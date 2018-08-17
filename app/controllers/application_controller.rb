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

  get '/album/:slug' do
    #binding.pry
    @album = Album.find_by_slug(params[:slug])
    erb :'/albums/view_album'
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

get '/album/:slug/edit' do
  @album = Album.find_by_slug(params[:slug])
  if logged_in? && @album.user.id == current_user.id
    erb :'/albums/edit_album'
  else
    redirect to "/albums"
  end
end

post '/album/:slug' do
  #binding.pry
  @album = Album.find_by_slug(params[:slug])
  if logged_in? && @album.user.id == current_user.id
    @album.update(name: params[:name]) unless params[:name].blank?
    @album.update(year_released: params[:year_released]) unless params[:year_released].blank?
    redirect to "/albums"
  else
    redirect to "/albums"
  end
end

delete '/album/:slug/delete' do
  #binding.pry
  @album = Album.find_by_slug(params[:slug])
  if logged_in? && @album.user.id == current_user.id
    @album.songs.each do |song|
      song.delete
    end

    @album.delete
    redirect to "/main"
  else
    redirect to "/main"
  end
end

################################ song controller

get '/song/new' do
  if logged_in?
    erb :'/songs/create_song'
  else
    redirect "/login"
  end
end

post '/song' do
  if logged_in?
    #binding.pry
    if !params[:song_name].blank? && !params[:track_length].blank?
      if params.keys.include?("albums")
          if !params[:albums].first.blank? && !params[:album][:name].blank?
            redirect "/song/new"
          elsif !params[:albums].first.blank?
            @album = Album.find_by_id(params[:albums])
            @song = Song.find_or_create_by(name: params[:song_name], track_length: params[:track_length], album_id: @album.id)
            @song.save
            redirect "/albums"
          else
            redirect "/song/new"
          end
      elsif !params[:album][:name].blank? && !params[:album][:year_released].blank?
        @user = User.find(session[:user_id])
        @album = Album.find_or_create_by(name: params[:album][:name], year_released: params[:album][:year_released], user_id: @user.id)
        @song = Song.find_or_create_by(name: params[:song_name], track_length: params[:track_length], album_id: @album.id)
        @album.save
        @song.save
        redirect "/albums"
      else
        redirect "/song/new"
      end

    else
      redirect "/song/new"
    end
  else
    redirect "/login"
  end
end

########

get '/album/:slug/:slug_s' do
  #binding.pry
  @album = Album.find_by_slug(params[:slug])
  @song = Song.find_by_slug(params[:slug_s])
  erb :'/songs/show_song'
end

delete '/album/:slug/:slug_s/delete' do
  #binding.pry
  @song = Song.find_by_slug(params[:slug_s])
  if logged_in? && @song.album.user.id == current_user.id
    @song.delete
    redirect to "/main"
  else
    redirect to "/main"
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
