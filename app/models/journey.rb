class Journey < ApplicationRecord
  after_create :write_cache
  after_update :write_cache

  belongs_to :user
  belongs_to :buddy
  has_many :buddy_personalities
  has_many :personalities, through: :buddy_personalities
  has_many :journey_archives
  has_many :chats
  has_many :missions

  module Status
    PREPARING = 1
    TRAVELING = 2
    COMPLETED = 3
  end

  module Cache
    JOURNEY_BY_ID = {
      key: 'journey_h_by_id_%{journey_id}',
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

    def write_journey_hash_cache_by_id(journey_hash)
      key, options = cache_info_by_id(journey_hash[:id])
      Rails.cache.write(key, journey_hash, options)
    end

    def valid_status?(status)
      [Status::PREPARING, Status::TRAVELING, Status::COMPLETED].include?(status)
    end

    def preparing?(journey_hash)
      journey_hash[:status] == Status::PREPARING
    end

    private

    def cache_info_by_id(id)
      key = format(Cache::JOURNEY_BY_ID[:key], journey_id: id)
      options = Cache::JOURNEY_BY_ID[:options]
      [key, options]
    end
  end

  private

  def write_cache
    journey_hash = self.attributes.symbolize_keys
    Journey.write_journey_hash_cache_by_id(journey_hash)
  end
end
