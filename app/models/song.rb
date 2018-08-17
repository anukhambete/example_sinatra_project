class Song < ActiveRecord::Base
  belongs_to :album


  def slug
    a = self.name.downcase
    #binding.pry
    if a.gsub!(/[!@% &"]/,'-')
      slug = a
      #binding.pry
    else
      slug = a
    end
    slug
  end

  def self.find_by_slug(slug)
    value = nil
    Song.all.each do |song|
      #binding.pry
      if song.slug == slug
        #binding.pry
        #val = artist
        value = song
      end
    end
    value
  end

end
