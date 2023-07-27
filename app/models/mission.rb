class Mission < ApplicationRecord
  belongs_to :user
  belongs_to :quest
  belongs_to :journey

  module Status
    ON_GOING = 1 # 퀘스트 진행중
    COMPLETED = 2 # 미션 완료
    REJECTED = 3 # 수행거부
  end

  module Cache
    MISSION_BY_ID = {
      key: 'mission_h_by_%{mission_id}',
      options: { expires_in: nil, raw: false }
    }
    COMPLETED_MISSION_BY_USER_ID = {
      key: 'completed_missions_by_q_id_%{quest_id}_u_id_%{user_id}',
      options: { expires_in: nil, raw: false }
    }
    REJECTED_MISSION_BY_USER_ID = {
      key: 'rejected_missions_by_q_id_%{quest_id}_u_id_%{user_id}',
      options: { expires_in: nil, raw: false }
    }
  end

  class << self
    # @param [Integer] id 미션id
    # @param [Boolean] force 강제로 DB에서 값을 가져와야할 경우에는 true값. 기본값은 false
    # @return [Hash] 미션 객체 정보
    def fetch_mission_hash_by_id(id, force: false)
      key, options = cache_info_by_id(id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        Mission.find_by(id: id)&.attributes.symbolize_keys
      end
    end

    def fetch_completed_mission_by_quest_id_and_user_id(quest_id, user_id, force: false)
      key, options = cache_info_completed_mission_by_q_id_and_u_id(quest_id, user_id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        Mission.find_by(quest_id: quest_id, user_id: user_id, status: Status::COMPLETED)&.attributes.symbolize_keys
      end
    end

    def fetch_rejected_mission_by_quest_id_and_user_id(quest_id, user_id, force: false)
      key, options = cache_info_rejected_mission_by_q_id_and_u_id(quest_id, user_id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        Mission.find_by(quest_id: quest_id, user_id: user_id, status: Status::REJECTED)&.attributes.symbolize_keys
      end
    end

    private

    def cache_info_by_id(id)
      key = format(Cache::MISSION_BY_ID[:key], mission_id: id)
      options = Cache::MISSION_BY_ID[:options]
      [key, options]
    end

    def cache_info_completed_mission_by_q_id_and_u_id(quest_id, user_id)
      key = format(Cache::COMPLETED_MISSION_BY_USER_ID[:key], quest_id: quest_id, user_id: user_id)
      options = Cache::COMPLETED_MISSION_BY_USER_ID[:options]
      [key, options]
    end

    def cache_info_rejected_mission_by_q_id_and_u_id(quest_id, user_id)
      key = format(Cache::REJECTED_MISSION_BY_USER_ID[:key], quest_id: quest_id, user_id: user_id)
      options = Cache::REJECTED_MISSION_BY_USER_ID[:options]
      [key, options]
    end
  end
end
