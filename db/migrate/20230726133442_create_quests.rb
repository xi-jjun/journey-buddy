class CreateQuests < ActiveRecord::Migration[7.0]
  def change
    create_table :quests do |t|
      t.string :title
      t.string :content
      t.string :complete_condition
      t.references :reward_badge, foreign_key: false

      t.timestamps
    end

    add_index :quests, :title
    add_index :quests, :content
  end
end
