class CreatePhotos < ActiveRecord::Migration[7.1]
  def change
    create_table :photos do |t|
      t.jsonb :image_data, null: false, default: {}
      t.index :image_data, using: :gin
      t.belongs_to :user

      t.timestamps
    end
  end
end
