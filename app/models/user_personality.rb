class UserPersonality < ApplicationRecord
  belongs_to :user
  belongs_to :personality
end
