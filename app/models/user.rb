class User < ApplicationRecord
  has_many :journeys
  has_many :journey_archives

  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  module LoginPlatform
    DEFAULT = 1
    KAKAO = 2
    GOOGLE = 3
  end
end
