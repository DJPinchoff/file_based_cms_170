require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  redirect "/home"
end

get "/home" do
  erb :home, layout: :layout
end
