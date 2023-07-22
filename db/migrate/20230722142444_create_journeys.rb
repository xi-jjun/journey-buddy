class CreateJourneys < ActiveRecord::Migration[7.0]
  def change
    create_table :journeys do |t|
      t.string :title
      t.integer :status, limit: 1
      t.references :user, foreign_key: false

      t.timestamps
    end
  end
end
