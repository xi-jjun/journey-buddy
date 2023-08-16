class Chat < ApplicationRecord
  belongs_to :journey
  belongs_to :user

  module ContentType
    TEXT = 1
    IMAGE = 2
    VOICE = 3
    VIDEO = 4
  end

  module Writer
    ASSISTANT = 1 # Chat GPT
    USER = 2 # 사용자
    SYSTEM = 3 # 역할 설정
  end

  module Cache
    CHATS_BY_JOURNEY_ID = {
      key: 'chat_all_list_by_journey_id_%{journey_id}',
      options: { expires_in: 1.day, raw: false }
    }
  end

  class << self
    # @param [Integer] journey_id 여행id
    # @param [Boolean] force 강제로 DB에서 값을 가져와야할 경우에는 true값. 기본값은 false
    # @return [Hashes] 대화(Hash) 목록
    def fetch_all_chats_by_journey_id(journey_id, force: false)
      key, options = cache_info_by_journey_id(journey_id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        result = Oj.dump(Chat.where(journey_id: journey_id).map(&:as_json))
        result.present? ? Oj.load(result, symbol_keys: true) : []
      end
    end

    # @param [Integer] journey_id 여행 id
    # @param [Hashes] chat_hashes 대화(hash) 목록
    def write_cache_for_user_journey_chats_by_journey_id(journey_id, chat_hashes)
      key, options = cache_info_by_journey_id(journey_id)
      Rails.cache.write(key, chat_hashes, options)
    end

    private

    def cache_info_by_journey_id(journey_id)
      key = format(Cache::CHATS_BY_JOURNEY_ID[:key], journey_id: journey_id)
      options = Cache::CHATS_BY_JOURNEY_ID[:options]
      [key, options]
    end
  end
end
