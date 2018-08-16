require './config/environment'
require 'pry'

class ApplicationController < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  enable :sessions
  set :session_secret, "password_security"

  configure do
      set :public_folder, 'public'
      set :views, 'app/views'
    end

  get '/' do
    erb :'/users/create_user'
  end

end
