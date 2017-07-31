ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

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

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
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

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.txt does not exist!"
  end

  def test_editing_document
    create_document "changes.txt", "changes"
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, '<input type="submit"'
  end

  def test_updating_document
    create_document "changes.txt"
    post "/changes.txt/update", content: "Changing"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated successfully!"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Changing"
  end

  def test_new_document_button_on_index_page
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "New Document</a>"
  end
end
