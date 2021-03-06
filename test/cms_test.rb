ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"
require "yaml"

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    create_document "something_different.txt"


    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "something_different.txt"
  end

  def test_viewing_text_document
    create_document "changes.txt", "Changing"

    get "/changes.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Changing"
  end

  def test_viewing_markdown_document
    create_document "about.md", '# Ruby is...'
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_error_message_for_invalid_file
    create_document "isafile.txt"

    get "/notafile.txt"
    assert_equal 302, last_response.status
    assert_equal "notafile.txt does not exist! Try one of these files:", session[:message]
  end

  def test_editing_document_signed_in
    create_document "changes.txt", "changes"
    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, '<input type="submit"'
  end

  def test_editing_document_signed_out
    create_document "changes.txt", "changes"
    get "/changes.txt/edit"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_updating_document_signed_in
    create_document "changes.txt"
    post "/changes.txt/update", { content: "Changing" }, admin_session

    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated successfully!", session[:message]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Changing"
  end

  def test_updating_document_signed_out
    create_document "changes.txt"
    post "/changes.txt/update", content: "Changing"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_new_document_button_on_index_page
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "New Document</a>"
  end

  def test_view_new_document_form_signed_in
    get "/new_file/create", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_view_new_document_form_signed_out
    get "/new_file/create"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_create_new_document_signed_in
    post "/new_file/save", { file: "test.txt" }, admin_session
    assert_equal 302, last_response.status
    assert_equal "test.txt was created.", session[:message]

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_signed_out
    post "/new_file/save", file: "test.txt"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_create_new_document_without_filename
    post "/new_file/save", { file: "" }, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid filename"
  end

  def test_deleting_document_signed_in
    create_document("test.txt")

    post "/test.txt/delete", {}, admin_session

    assert_equal 302, last_response.status
    assert_equal "test.txt was deleted.", session[:message]

    get "/"
    refute_includes last_response.body, "href=\"test.txt\""
  end

  def test_deleting_document_signed_out
    create_document("test.txt")

    post "/test.txt/delete"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_signin
    post "/users/authenticate", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    post "/users/authenticate", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_signout
    get "/", {}, {"rack.session" => { username: "admin" } }
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    get last_response["Location"]

    assert_nil session[:username]
    assert_includes last_response.body, "You have been signed out"
    assert_includes last_response.body, "Sign In"
  end
end
