class CreateUserPersonalities < ActiveRecord::Migration[7.0]
  def change
    create_table :user_personalities, id: false do |t|
      t.references :user, foreign_key: false
      t.references :personality, foreign_key: false
    end

    add_index :user_personalities, [:user_id, :personality_id]
  end
end
