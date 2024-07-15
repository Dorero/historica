class CreatePhotos < ActiveRecord::Migration[7.1]
  def change
    create_table :photos do |t|
      t.jsonb :image_data, null: false, default: {}
      t.index :image_data, using: :gin
      t.references :imageable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
