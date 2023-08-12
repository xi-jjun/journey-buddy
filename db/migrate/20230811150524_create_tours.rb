class CreateTours < ActiveRecord::Migration[7.0]
  def change
    create_table :tours, id: false do |t|
      t.integer :content_id, unique: true
      t.string :title
      t.string :address
      t.integer :area_code
      t.string :first_image
      t.float :lat
      t.float :lng
      t.integer :content_type_id
    end

    add_index :tours, :title
    add_index :tours, :address
  end
end
