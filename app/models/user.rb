class User < ApplicationRecord
  has_many :journeys
  has_many :journey_archives
  has_many :missions
  has_many :user_personalities
  has_many :personalities, through: :user_personalities

  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  module LoginPlatform
    DEFAULT = 1
    KAKAO = 2
    GOOGLE = 3
  end
end
