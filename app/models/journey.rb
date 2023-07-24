class Journey < ApplicationRecord
  belongs_to :user
  has_many :buddy_personalities
  has_many :personalities, through: :buddy_personalities
  has_many :journey_archives
  has_many :chats

  module Status
    READY_TO_ONBOARDING = 1
    TRAVELING = 2
    COMPLETED = 3
  end
end
