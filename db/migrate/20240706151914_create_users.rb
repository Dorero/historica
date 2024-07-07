class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.string :handle, null: false, index: { unique: true }
      t.string :password
      t.string :password_digest

      t.timestamps
    end
  end
end