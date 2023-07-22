class CreatePersonalities < ActiveRecord::Migration[7.0]
  def change
    create_table :personalities do |t|
      t.string :display_name
      t.text :description

      t.timestamps
    end

    add_index :personalities, :display_name
  end
end
