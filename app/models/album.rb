class Album < ActiveRecord::Base
  belongs_to :user
  has_many :songs

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
    Album.all.each do |album|
      #binding.pry
      if album.slug == slug
        #binding.pry
        #val = artist
        value = album
      end
    end
    value
  end

end
