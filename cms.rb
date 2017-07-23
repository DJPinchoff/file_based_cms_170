require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  erb :home, layout: :layout
end
