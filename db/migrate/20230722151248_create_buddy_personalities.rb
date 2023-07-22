class CreateBuddyPersonalities < ActiveRecord::Migration[7.0]
  def change
    create_table :buddy_personalities do |t|
      t.references :personality, foreign_key: false
      t.references :journey, foreign_key: false

      t.timestamps
    end

    add_index :buddy_personalities, [:personality_id, :journey_id], name: 'idx_buddy_personalities_on_personality_id__journey_id'
  end
end
