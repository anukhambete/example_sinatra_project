class AlbumsController < ApplicationController
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


  if !params[:name].blank? && !params[:year_released].blank? && @input_year.scan(/\D/).empty?
      @user.albums.each do |album|
        @message = nil
        if album.name.gsub(" ","").downcase == @input_name
          if @input_year.scan(/\D/).empty? && album.year_released.gsub(" ","") == @input_year
            @message = "The album already exists."
            #flash[:message] = "The album already exists."
            #redirect "/albums"   #include flash message saying the album already exists
          end
        end
        @message
      end

      if @message != nil
        flash[:message] = "The album already exists."
        redirect "/albums"   #include flash message saying the album already exists
      else
        @album = Album.find_or_create_by(name: params[:name], year_released: @input_year)
        @user.albums << @album
        @user.save
        @album.save
        flash[:message] = "Successfully created album."
        redirect "/albums"
      end
    #binding.pry

  elsif !params[:name].blank? && params[:year_released].blank?
    @user.albums.each do |album|
      if album.name.gsub(" ","").downcase == @input_name
          flash[:message] = "The album already exists."
          redirect "/albums"   #include flash message saying the album already exists
      end
    end
  else
    flash[:message] = "Please enter a valid name and year of release."
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
      if params[:name].blank? || params[:year_released].blank?
        flash[:message] = "Enter a valid name and year of release."
        redirect to "/albums"
      else
        @album.update(name: params[:name]) unless params[:name].blank?
        @album.update(year_released: params[:year_released]) unless params[:year_released].blank?
        flash[:message] = "Successfully updated album."
        redirect to "/albums"
      end
    else
      flash[:message] = "You cannot edit the album."
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
      flash[:message] = "Successfully deleted album."
      redirect to "/albums"
    else
      flash[:message] = "You cannot delete that album."
      redirect to "/albums"
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
