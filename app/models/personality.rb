class Personality < ApplicationRecord
  has_many :buddy_personalities
  has_many :journeys, through: :buddy_personalities
  has_many :user_personalities
  has_many :users, through: :user_personalities

  module Cache
    PERSONALITY_BY_ID = {
      key: 'personality_h_by_id_%{personality_id}',
      options: { expires_in: nil, raw: false }
    }
  end

  class << self
    # @param [Integer] personality_id 성격(태그)id
    # @param [Boolean] force 강제로 DB에서 값을 가져와야할 경우에는 true값. 기본값은 false
    # @return [Hash] 성격(태그) 객체 정보
    def fetch_personality_by_id(personality_id, force: false)
      key, options = cache_info_for_personality_id(personality_id)
      Rails.cache.fetch(key, options.merge!(force: force)) do
        Personality.find_by(id: personality_id).attributes.symbolize_keys
      end
    end

    private

    def cache_info_for_personality_id(personality_id)
      key = format(Cache::PERSONALITY_BY_ID[:key], personality_id: personality_id)
      options = Cache::PERSONALITY_BY_ID[:options]
      [key, options]
    end
  end
end
