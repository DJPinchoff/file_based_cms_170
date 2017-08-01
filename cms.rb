require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "fileutils"

configure do
  enable :sessions
  set :session_secret, 'secret'
end


def data_path
  if ENV["RACK_ENV"] == "test"
    Dir.pwd + "/test/data"
  else
    Dir.pwd + "/data"
  end
end

def data_filenames
  Dir.new(data_path).select { |file| file.match?(/.+\..+/) }
end

def valid_file?(filename)
  data_filenames.include? filename
end

def valid_filename?(filename)
  filename.match?(/.+\..+/)
end

def render_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file.read)
end

def parse_content(path, pure_content=nil)
  extension = path.split(".").last
  extension = "txt" if pure_content == :pure_content
  file = File.new(path)
  case extension
  when "md"
    render_markdown(file)
  when "txt"
    headers["Content-Type"] = "text/plain"
    file.read
  end
end

# List all files in the data directory
get "/" do
  @filenames = data_filenames

  erb :index, layout: :layout
end

# Show the contents of a specific file
get "/:filename" do
  @filename = params[:filename]
  if valid_file?(@filename)
    path = File.join(data_path, @filename)
    parse_content(path)
  else
    session[:message] = "#{@filename} does not exist! Try one of these files:"
    redirect "/"
  end
end

# Display form to edit contents of file
get "/:filename/edit" do
  @filename = params[:filename]
  if valid_file?(@filename)
    @path = File.join(data_path, @filename)
    @content = parse_content(@path, :pure_content)
    headers["Content-Type"] = "text/html"
    erb :edit
  else
    session[:message] = "#{@filename} does not exist! Try one of these files:"
    redirect "/"
  end
end

# Update/save changes made to file
post "/:filename/update" do
  filename = params[:filename]
  content = params[:content]
  path = File.join(data_path, filename)
  File.write(path, content)
  session[:message] = "#{filename} has been updated successfully!"
  redirect "/"
end

# Create a new file
get "/new_file/create" do
  erb :create, layout: :layout
end

# Save a valid new file
post "/new_file/save" do
  if params[:file]
    filename = params[:file]
    if valid_filename?(filename)
      File.open(File.join(data_path, filename), "w") {}
      session[:message] = "#{filename} was created."
      status 302
      redirect "/"
    else
      session[:message] = "Invalid filename!"
      status 422
      erb :create, layout: :layout
    end
  end
end

post "/:filename/delete" do
  filename = params[:filename]
  if valid_filename?(filename)
    File.delete(File.join(data_path, filename))
    session[:message] = "#{filename} was deleted."
    redirect "/"
  else
    session[:message] = "#{filename} does not exist! Try one of these files:"
    redirect "/"
  end
end
