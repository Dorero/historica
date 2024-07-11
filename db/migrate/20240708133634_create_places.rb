class CreatePlaces < ActiveRecord::Migration[7.1]
  def change
    create_table :places do |t|
      t.string :title, null: false
      t.text :description
      t.integer :date, null: false
      t.jsonb :_geo, null: false, default: { lat: 0.0, lng: 0.0 }

      t.timestamps
    end
  end
end
