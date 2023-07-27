class RewardBadge < ApplicationRecord
  has_one :quest

  module Cache
    REWARD_BADGE_BY_ID = {
      key: 'reward_badge_h_by_%{reward_badge_id}',
      options: { expires_in: nil, raw: false }
    }
  end

  class << self
    # @param [Integer] id 뱃지id
    # @param [Boolean] force 강제로 DB에서 값을 가져와야할 경우에는 true값. 기본값은 false
    # @return [Hash] 완료시 받을 수 있는 뱃지 정보
    def fetch_reward_badge_hash_by_id(id, force: false)
      key, options = cache_info_by_id(id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        RewardBadge.find_by(id: id)&.attributes.symbolize_keys
      end
    end

    private

    def cache_info_by_id(id)
      key = format(Cache::REWARD_BADGE_BY_ID[:key], reward_badge_id: id)
      options = Cache::REWARD_BADGE_BY_ID[:options]
      [key, options]
    end
  end
end
