class AddBuddyIdToJourneys < ActiveRecord::Migration[7.0]
  def change
    add_column :journeys, :buddy_id, :bigint, after: :user_id
  end
end
