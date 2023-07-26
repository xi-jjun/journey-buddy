class Mission < ApplicationRecord
  belongs_to :user
  belongs_to :quest
  belongs_to :journey
end
