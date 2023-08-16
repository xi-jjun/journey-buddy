class ModifyChatLocationColumnType < ActiveRecord::Migration[7.0]
  def change
    change_column :chats, :latitude, :decimal, precision: 9, scale: 6
    change_column :chats, :longitude, :decimal, precision: 9, scale: 6
  end
end
