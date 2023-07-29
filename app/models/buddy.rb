class Buddy < ApplicationRecord
  after_create :write_cache
  after_update :write_cache

  module Gender
    MAN = 1
    WOMAN = 2
  end

  module Cache
    BUDDY_BY_ID = {
      key: 'buddy_h_by_id_%{buddy_id}',
      options: { expires_in: nil, raw: false }
    }
  end

  class << self
    # @param [Integer] id 동행AI id
    # @param [Boolean] force 강제로 DB에서 값을 가져와야할 경우에는 true값. 기본값은 false
    # @return [Hash] 동행AI 객체 정보
    def fetch_buddy_hash_by_id(id, force: false)
      key, options = cache_info_by_id(id)
      Rails.cache.fetch(key, options.merge(force: force)) do
        Buddy.find_by(id: id).attributes.symbolize_keys
      end
    end

    def write_buddy_hash_cache_by_id(buddy_hash)
      key, options = cache_info_by_id(buddy_hash[:id])
      Rails.cache.write(key, buddy_hash, options)
    end

    private

    def cache_info_by_id(id)
      key = format(Cache::BUDDY_BY_ID[:key], buddy_id: id)
      options = Cache::BUDDY_BY_ID[:options]
      [key, options]
    end
  end

  private

  def write_cache
    buddy_hash = self.attributes.symbolize_keys
    Buddy.write_buddy_hash_cache_by_id(buddy_hash)
  end
end
