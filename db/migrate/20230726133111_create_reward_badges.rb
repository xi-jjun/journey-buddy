class CreateRewardBadges < ActiveRecord::Migration[7.0]
  def change
    create_table :reward_badges do |t|
      t.string :name
      t.string :description
      t.string :image_url

      t.timestamps
    end

    add_index :reward_badges, [:name, :image_url]
    add_index :reward_badges, :created_at
  end
end
