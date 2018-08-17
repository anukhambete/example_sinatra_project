class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
          t.string :name
          t.string :track_length
          t.integer :album_id
      end
  end
end
