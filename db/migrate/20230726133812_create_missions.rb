class CreateMissions < ActiveRecord::Migration[7.0]
  def change
    create_table :missions do |t|
      t.integer :status, limit: 1
      t.datetime :completed_at
      t.references :user, foreign_key: false
      t.references :quest, foreign_key: false
      t.references :journey, foreign_key: false

      t.timestamps
    end

    add_index :missions, [:user_id, :journey_id]
    add_index :missions, :completed_at
  end
end
