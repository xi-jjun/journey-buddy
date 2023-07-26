class Quest < ApplicationRecord
  has_one :reward_badge
  has_many :missions

  module Cache
    QUEST_BY_ID = {
      key: 'quest_h_by_id_%{quest_id}',
      options: { expires_in: nil, raw: false }
    }
  end

  class << self
    # @param [Integer] id 퀘스트id
    # @param [Boolean] force 강제로 DB에서 값을 가져와야할 경우에는 true값. 기본값은 false
    # @return [Hash] 퀘스트 객체 정보
    def fetch_quest_hash_by_id(id, force: false)
      key, options = cache_info_by_id(id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        Quest.find_by(id: id).attributes.symbolize_keys
      end
    end

    private

    def cache_info_by_id(id)
      key = format(Cache::QUEST_BY_ID[:key], quest_id: id)
      options = Cache::QUEST_BY_ID[:options]
      [key, options]
    end
  end
end
