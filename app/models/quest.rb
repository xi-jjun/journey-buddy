class Quest < ApplicationRecord
  has_one :reward_badge
  has_many :missions
end
