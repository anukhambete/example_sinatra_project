class SongsController < ApplicationController
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
            #binding.pry
            if song.name.gsub(" ","").downcase == @input_name && song.track_length.gsub(" ","") == @input_time
              flash[:message] = "This song already exists as part of this album."
              redirect to "/album/#{song.album.slug}/edit" #add flash message  song already exists in album
            end
          end
        end



      if !params[:song_name].blank? && !params[:track_length].blank?
        if params.keys.include?("albums")
            if !params[:albums].first.blank? && !params[:album][:name].blank?
              flash[:message] = "Please create or choose an existing album."
              redirect "/song/new"
            elsif !params[:albums].first.blank?
              @album = Album.find_by_id(params[:albums])
              if @album.user_id == current_user.id
                @song = Song.find_or_create_by(name: params[:song_name], track_length: params[:track_length], album_id: @album.id)
                @song.save
                flash[:message] = "Song was successfully created."
                #redirect "/albums"
                redirect to "/album/#{@song.album.slug}/edit"
              else
                flash[:message] = "Please create or choose an existing album."
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
            @album
          end

            if @album == nil
              @album = Album.find_or_create_by(name: params[:album][:name], year_released: @input_ayear, user_id: @user.id)
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
          flash[:message] = "Song was successfully created."
          redirect to "/album/#{@song.album.slug}/edit"
        else
          flash[:message] = "Please create or choose an existing album."
          redirect "/song/new"
        end

      else
        flash[:message] = "Please enter a song name and track length."
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
        flash[:message] = "Enter a song name and track length"
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
              @album_correct = Album.find_or_create_by(name: params[:album][:name], year_released: @input_ayear, user_id: @user.id)
            end
          #@album_correct = Album.find_or_create_by(name: params[:album][:name], year_released: params[:album][:year_released], user_id: @user.id)
            #binding.pry
            @song.update(name: params[:song_name], track_length: params[:track_length], album_id: @album_correct.id)
            @album_correct.save
            @song.save
            flash[:message] = "Successfully updated song."
            redirect "/albums"   #include flash message
      elsif params.keys.include?("albums")
              if !params[:albums].first.blank? && !params[:album][:name].blank?
                redirect "/album/#{@album.slug}/#{@song.slug}/edit"
              elsif !params[:albums].first.blank?
                @album_correct = Album.find_by_id(params[:albums])
                @song.update(name: params[:song_name], track_length: params[:track_length], album_id: @album_correct.id)
                @song.save
                flash[:message] = "Successfully updated song."
                redirect "/albums"
              end
      else
          redirect "/song/#{@album.slug}/#{@song.slug}/edit"
      end

    else
      flash[:message] = "You cannot edit that song."
      redirect "/albums"
    end

  end

  delete '/song/:slug/:slug_s/delete' do
    #binding.pry
    @song = Song.find_by_slug(params[:slug_s])
    if logged_in? && @song.album.user.id == current_user.id
      @song.delete
      flash[:message] = "Successfully deleted song."
      redirect to "/albums"
    else
      flash[:message] = "You cannot delete that song."
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
