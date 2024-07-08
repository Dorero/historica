class AddPlaceToPhotos < ActiveRecord::Migration[7.1]
  def change
    add_reference :photos, :place, index: true
  end
end
