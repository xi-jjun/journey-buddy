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

  module Cache
    JOURNEY_BY_ID = {
      key: 'journey_h_by_id_%{id}',
      options: { expires_in: 7.days, raw: false }
    }
  end

  class << self
    # @param [Integer] id 여행id
    # @param [Boolean] force 강제로 DB에서 값을 가져와야할 경우에는 true값. 기본값은 false
    # @return [Hash] 여행 객체 정보
    def fetch_journey_hash_by_id(id, force: false)
      key, options = cache_info_by_id(id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        Journey.find_by(id: id).attributes.symbolize_keys
      end
    end

    def valid_status?(status)
      [Status::READY_TO_ONBOARDING, Status::TRAVELING, Status::COMPLETED].include?(status)
    end

    private

    def cache_info_by_id(id)
      key = format(Cache::JOURNEY_BY_ID[:key], id: id)
      options = Cache::JOURNEY_BY_ID[:options]
      [key, options]
    end
  end
end
