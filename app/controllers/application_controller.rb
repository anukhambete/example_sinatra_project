require './config/environment'
require 'pry'

class ApplicationController < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  enable :sessions
  set :session_secret, "password_security"

  configure do
      set :public_folder, 'app/public'
      set :views, 'app/views'
      #set :public_folder, File.expand_path('../public', __FILE__)
      #set :views        , File.expand_path('/views', __FILE__)
      #set :root         , File.dirname(__FILE__)
    end

  get '/' do
    erb :index
  end

  get '/main' do
    if logged_in?
      @albums = Album.all
      @user = User.find(session[:user_id])
        erb :'/main'
    else
      redirect to "/login"
    end

  end

  get '/signup' do
    if logged_in?
      @albums = Album.all
      @user = User.find(session[:user_id])
        erb :'/main'
    else
      erb :'/users/create_user'
    end
  end


  post '/signup' do
    #binding.pry
    #if logged in - flash message : you must log out first to sign up as a diff user
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
      redirect "/main"
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
      @albums = Album.all.order(user_id: :desc).order(year_released: :asc)
      @user = User.find(session[:user_id])
        erb :'/albums/albums'
    else
      redirect to "/login"
    end
  end

  get '/album/new' do  #create album form
    if logged_in?
      erb :'/albums/create_album'
    else
      redirect "/login"
    end
  end

  get '/album/:slug' do  #view album
    #binding.pry
    @album = Album.find_by_slug(params[:slug])
    erb :'/albums/view_album'
  end

  post '/album' do #create album action

  @user = User.find(session[:user_id])
  @input_name = params[:name].gsub(" ","").downcase
  @input_year = params[:year_released].gsub(" ","")
  #binding.pry
  @user.albums.each do |album|
    if album.name.gsub(" ","").downcase == @input_name
      if @input_year.scan(/\D/).empty? && album.year_released.gsub(" ","") == @input_year
        redirect "/albums"   #include flash message saying the album already exists
      end
    end
  end

  if !params[:name].blank? && !params[:year_released].blank?
    @album = Album.find_or_create_by(name: params[:name], year_released: params[:year_released])
    if @user.albums.include?(@album)
      redirect "/albums"  #include flash message saying the album already exists
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

get '/album/:slug/edit' do  #edit album form
  @album = Album.find_by_slug(params[:slug])
  if logged_in? && @album.user.id == current_user.id
    erb :'/albums/edit_album'
  else
    redirect to "/albums"
  end
end

post '/album/:slug' do #edit album action
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

get '/song/new' do #form to create new song
  if logged_in?
    @user = User.find(session[:user_id])
    erb :'/songs/create_song'
  else
    redirect "/login"
  end
end

post '/song' do                        #create song action
  if logged_in?
    #binding.pry

    @input_name = params[:song_name].gsub(" ","").downcase
    @input_time = params[:track_length].gsub(" ","")


      if params.keys.include?("albums")
        @album = Album.find_by_id(params[:albums])
        @album.songs.each do |song|
          if song.name.gsub(" ","").downcase == @input_name && song.track_length.gsub(" ","") == @input_time
            redirect "/song/new" #add flash message  song already exists in album
          end
        end
      end



    if !params[:song_name].blank? && !params[:track_length].blank?
      if params.keys.include?("albums")
          if !params[:albums].first.blank? && !params[:album][:name].blank?
            redirect "/song/new"
          elsif !params[:albums].first.blank?
            @album = Album.find_by_id(params[:albums])
            if @album.user_id == current_user.id
              @song = Song.find_or_create_by(name: params[:song_name], track_length: params[:track_length], album_id: @album.id)
              @song.save
              redirect "/albums"
            else
              redirect "/song/new"
            end
          else
            redirect "/song/new"
          end
      elsif !params[:album][:name].blank? && !params[:album][:year_released].blank?
        #binding.pry
        @user = User.find_by_id(session[:user_id])

        @input_aname = params[:album][:name].gsub(" ","").downcase
        @input_ayear = params[:album][:year_released].gsub(" ","")

        @user.albums.each do |album|
          if album.name.gsub(" ","").downcase == @input_aname
            if @input_ayear.scan(/\D/).empty? && album.year_released.gsub(" ","") == @input_ayear
              @album = album
            end
          end
        end

          if @album == nil
            @album = Album.find_or_create_by(name: params[:album][:name], year_released: params[:album][:year_released], user_id: @user.id)
          end

        @album.songs.each do |song|
          if song.name.gsub(" ","").downcase == @input_name
            if song.track_length.gsub(" ","") == @input_time
              @song = song
            end
          end
        end

          if @song == nil
            @song = Song.find_or_create_by(name: params[:song_name], track_length: params[:track_length], album_id: @album.id)
          end


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

get '/song/:slug/:slug_s' do #view song
  #binding.pry
  @album = Album.find_by_slug(params[:slug])
  @song = Song.find_by_slug(params[:slug_s])
  erb :'/songs/show_song'
end

get '/song/:slug/:slug_s/edit' do  #edit song form
  #binding.pry
  @album = Album.find_by_slug(params[:slug])
  @song = Song.find_by_slug(params[:slug_s])
  @user = User.find_by_id(session[:user_id])
  erb :'/songs/edit_song'
end

post '/song/:slug/:slug_s' do #edit song action
  #binding.pry
  @song = Song.find_by_slug(params[:slug_s])
  @album = Album.find_by_slug(params[:slug])
  #binding.pry
  if logged_in? && @song.album.user.id == current_user.id
    if params[:song_name].blank? || params[:track_length].blank?
      redirect to "/song/#{@album.slug}/#{@song.slug}/edit"
    end


    if !params[:album][:name].blank? && !params[:album][:year_released].blank?
      #binding.pry
        @user = User.find_by_id(session[:user_id])
        @input_aname = params[:album][:name].gsub(" ","").downcase
        @input_ayear = params[:album][:year_released].gsub(" ","")

        @user.albums.each do |album|
          if album.name.gsub(" ","").downcase == @input_aname
            if @input_ayear.scan(/\D/).empty? && album.year_released.gsub(" ","") == @input_ayear
              @album_correct = album
            end
          end
        end

          if @album_correct == nil
            @album_correct = Album.find_or_create_by(name: params[:album][:name], year_released: params[:album][:year_released], user_id: @user.id)
          end
        #@album_correct = Album.find_or_create_by(name: params[:album][:name], year_released: params[:album][:year_released], user_id: @user.id)
          #binding.pry
          @song.update(name: params[:song_name], track_length: params[:track_length], album_id: @album_correct.id)
          @album_correct.save
          @song.save
          redirect "/albums"   #include flash message
    elsif params.keys.include?("albums")
            if !params[:albums].first.blank? && !params[:album][:name].blank?
              redirect "/album/#{@album.slug}/#{@song.slug}/edit"
            elsif !params[:albums].first.blank?
              @album_correct = Album.find_by_id(params[:albums])
              @song.update(name: params[:song_name], track_length: params[:track_length], album_id: @album_correct.id)
              @song.save
              redirect "/albums"
            end
    else
        redirect "/song/#{@album.slug}/#{@song.slug}/edit"
    end

  else
    redirect "/albums"
  end

end

delete '/song/:slug/:slug_s/delete' do
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
