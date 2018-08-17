class CreateAlbums < ActiveRecord::Migration
  def change
    create_table :albums do |t|
          t.string :name
          t.string :year_released
          t.integer :user_id
      end
  end
end
