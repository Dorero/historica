class CreatePlaces < ActiveRecord::Migration[7.1]
  def change
    create_table :places do |t|
      t.string :title, null: false
      t.text :description
      t.integer :date, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false

      t.timestamps
    end
  end
end
