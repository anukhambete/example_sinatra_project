require './config/environment'
require 'pry'

class ApplicationController < Sinatra::Base
  configure do
      set :views, 'app/views'
    end

  get '/' do
    erb :main
  end

end
