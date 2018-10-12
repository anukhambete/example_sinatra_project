require './config/environment'
require 'pry'
require 'rack-flash'

class ApplicationController < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  use Rack::Flash
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
    if logged_in?
      flash[:message] = "You must log out first to sign up as a different user."
      redirect to "/main"
    elsif !params[:username].blank? && !params[:password].blank? && !params[:email].blank? && !User.exists?(username: params[:username])
      #add code to ensure the username is unique and add error messages
      @user = User.new(username: params[:username], password: params[:password], email: params[:email])
      @user.save
      session[:user_id] = @user.id
      flash[:message] = "Sign Up successful!"
      redirect to "/main"
    else
      #"Enter a valid username, password and email address"
      flash[:message] = "Enter a valid/different username, password and email address. Do not leave any fields blank."
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
      flash[:message] = "Enter a valid username and password combination OR signup."
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



################################ song controller





  helpers do
    def logged_in?
      !!session[:user_id]
    end

    def current_user
      User.find(session[:user_id])
    end
  end

end
