class CreateJourneyArchives < ActiveRecord::Migration[7.0]
  def change
    create_table :journey_archives do |t|
      t.string :display_name
      t.string :filename
      t.string :file_url
      t.integer :content_type, limit: 1
      t.references :journey, foreign_key: false
      t.references :user, foreign_key: false

      t.timestamps
    end

    add_index :journey_archives, :filename
    add_index :journey_archives, :display_name
  end
end
