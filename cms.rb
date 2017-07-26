require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "fileutils"

configure do
  enable :sessions
  set :session_secret, 'secret'
end


def data_dir
  if ENV["RACK_ENV"] == "test"
    Dir.new(Dir.pwd + "/test/data")
  else
    Dir.new(Dir.pwd + "/data")
  end
end

def data_filenames
  data_dir.select { |file| file.match?(/.+\..+/) }
end

def valid_filename?(filename)
  data_filenames.include? filename
end

def parse_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file.read)
end

def parse_content(path)
  extension = path.split(".").last
  file = File.new(path)
  case extension
  when "md"
    parse_markdown(file)
  when "txt"
    headers["Content-Type"] = "text/plain"
    file.read
  end
end

# List all files in the data directory
get "/" do
  @filenames = data_filenames

  erb :index
end

# Show the contents of a specific file
get "/:filename" do
  @filename = params[:filename]
  if valid_filename?(@filename)
    path = Dir.pwd + "/data/" + @filename
    parse_content(path)
  else
    session[:message] = "#{@filename} does not exist! Try one of these files:"
    redirect "/"
  end
end

# Display form to edit contents of file
get "/:filename/edit" do
  @filename = params[:filename]
  if valid_filename?(@filename)
    @path = Dir.pwd + "/data/" + @filename
    @content = parse_content(@path)
    headers["Content-Type"] = "text/html"
    erb :edit_file
  else
    session[:message] = "#{@filename} does not exist! Try one of these files:"
    redirect "/"
  end
end

# Update/save changes made to file
post "/:filename/update" do
  filename = params[:filename]
  content = params[:content]
  path = Dir.pwd + "/data/" + filename
  File.write(path, content)
  session[:message] = "#{filename} has been updated successfully!"
  redirect "/"
end
