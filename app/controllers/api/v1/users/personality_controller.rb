class Api::V1::Users::PersonalityController < ApplicationController
  before_action :validate_jwt

  # 사용자의 성향을 설정하는 기능
  # @param [String] personalities 1,2,3,4... 콤마로 분리된 문자열
  def create_user_personality_settings
    user_hash = @user.attributes.symbolize_keys

    personality_ids = params[:personalities].split(',').map(&:to_i)
    @personality_hashes = Rails.cache.read_multi(*personality_ids, raw: true)
    @personality_hashes = Personality.where(id: personality_ids).map { |personality| personality.attributes.symbolize_keys } unless @personality_hashes.present?
    raise 'invalid parameter' unless @personality_hashes.present?

    @personality_hashes.each do |personality_hash|
      UserPersonality.create!(user_id: user_hash[:id], personality_id: personality_hash[:id])
    end

    render json: { code: 200, message: 'success' }
  rescue StandardError => e
    Rails.logger.warn("fail user_personality_settings api error=#{e.message}|backtrace=#{e.backtrace}")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  # 사용자 ID의 성향을 가져오는 API
  def get_user_personalities
    user_personalities = @user.personalities
    if user_personalities.blank?
      render json: { code: 200, user_personalities: [] }
      return
    end

    personality_hashes = user_personalities.map { |user_personality| user_personality.attributes.symbolize_keys }

    # TODO : 일단 모든 정보 보내고, 나중에 필요하다면 필수적인 정보만 보내기
    render json: { code: 200, user_personalities: personality_hashes }
  rescue StandardError => e
    Rails.logger.warn("fail get_user_personalities api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  def reset_user_personality
    user_personalities = @user.personalities
    if user_personalities.blank?
      render json: { code: 1, message: '유저 성향 테스트 정보가 존재하지 않습니다.' }
      return
    end

    @user.personalities.delete_all

    render json: { code: 200 }
  rescue StandardError => e
    Rails.logger.error("fail reset_user_personality api error=#{e.message}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end
end
