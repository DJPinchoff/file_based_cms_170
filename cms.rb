require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"


def data_dir
  Dir.new(Dir.pwd + "/data")
end

def data_file_names
  data_dir.select { |file| file.match?(/.+\..+/) }
end

get "/" do
  @data_files = data_file_names

  erb :index, layout: :layout
end

get "/:filename" do
  @title = params[:filename]
  path = Dir.pwd + "/data/" + params[:filename]
  @file = File.new(path)
  headers["Content-Type"] = "text/plain"
  headers["Title"] = "#{@title}"
  erb :file, layout: false
end
