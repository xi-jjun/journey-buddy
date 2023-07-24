class Personality < ApplicationRecord
  has_many :buddy_personalities
  has_many :journeys, through: :buddy_personalities
end
