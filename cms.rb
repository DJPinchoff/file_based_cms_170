require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"


def get_data_file_names
  results = []
  path = Dir.pwd + "/data"
  data_dir = Dir.new(path)
  data_dir.each { |file| results << file if file.match?(/.+\..+/) }

  results
end

get "/" do
  @data_files = get_data_file_names
  erb :index, layout: :layout
end
