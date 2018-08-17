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
    erb :index
  end

  get '/main' do
    erb :'/main'
  end

  get '/signup' do
    erb :'/users/create_user'
  end


  post '/signup' do
    #binding.pry
    if !params[:username].blank? && !params[:password].blank? && !params[:email].blank?
      @user = User.new(username: params[:username], password: params[:password], email: params[:email])
      @user.save
      session[:user_id] = @user.id
      redirect to "/main"
    else
      #"Enter a valid username, password and email address"
      redirect to "/signup"
    end
  end

  get '/login' do
    if logged_in?
      redirect to "/main"
    else
      erb :'/users/login'
    end
  end

  post "/login" do
    #binding.pry
    @user = User.find_by(:username => params[:username])
		if @user && @user.authenticate(params[:password])
      session[:user_id] = @user.id
      redirect "/albums"
    else
      redirect "/login"
    end
  end

  get "/logout" do
    if logged_in?
      session.clear
      redirect "/login"
    else
      redirect "/login"
    end
  end

#################################### album controller


  get '/albums' do
    #binding.pry
    if logged_in?
      @albums = Album.all
      @user = User.find(session[:user_id])
        erb :'/albums/albums'
    else
      redirect to "/login"
    end
  end

  get '/album/new' do
    if logged_in?
      erb :'/albums/create_album'
    else
      redirect "/login"
    end
  end

  post '/album' do
  #binding.pry
  @user = User.find(session[:user_id])
  if !params[:name].blank? && !params[:year_released].blank?
    @album = Album.find_or_create_by(name: params[:name], year_released: params[:year_released])
    if @user.albums.include?(@album)
      redirect "/albums"
    else
      @user.albums << @album
      @user.save
      @album.save
    end
    #binding.pry
    redirect "/albums"
  else
    redirect "/album/new"
  end
end

  helpers do
    def logged_in?
      !!session[:user_id]
    end

    def current_user
      User.find(session[:user_id])
    end
  end

end
