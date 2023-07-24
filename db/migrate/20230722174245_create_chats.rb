class CreateChats < ActiveRecord::Migration[7.0]
  def change
    create_table :chats do |t|
      t.integer :writer, limit: 1
      t.text :content
      t.integer :content_type, limit: 1
      t.references :journey, foreign_key: false
      t.references :user, foreign_key: false
      t.float :latitude
      t.float :longitude

      t.timestamps
    end

    add_index :chats, [:journey_id, :user_id]
    add_index :chats, [:latitude, :longitude]
    add_index :chats, :content, type: :fulltext
  end
end
