class Api::V1::Chats::PersonalityController < ApplicationController
  before_action :validate_and_set_personality_params, only: [:chat_role_setting]
  before_action :get_user_info_from_request, only: [:user_personality_settings, :user_personalities]

  def chat_role_list
    personalities = Personality.select(:id, :display_name).all.map(&:as_json)

    render json: { code: 200, personalities: personalities }
  end

  # @param [String] personalities 1,2,3,4... 콤마로 분리된 문자열
  def chat_role_setting
    user_hash = @user.attributes.symbolize_keys

    @personality_hashes.each do |personality_hash|
      BuddyPersonality.create!(personality_id: personality_hash[:id], journey_id: @journey_hash[:id])
      Chat.create!(writer: Chat::Writer::SYSTEM,
                   content: personality_hash[:description],
                   content_type: Chat::ContentType::TEXT,
                   journey_id: @journey_hash[:id],
                   user_id: user_hash[:id])
    end
    prepared_journey = Journey.find_by(id: @journey_hash[:id])
    prepared_journey.update!(status: Journey::Status::TRAVELING)

    render json: { code: 200, message: 'success' }
  rescue StandardError => e
    Rails.logger.error("fail chat_role_setting api error=#{e.message}")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  private

  def validate_and_set_personality_params
    personality_ids = params[:personalities].split(',').map(&:to_i)
    @personality_hashes = Rails.cache.read_multi(*personality_ids, raw: true)
    @personality_hashes = Personality.where(id: personality_ids).map { |personality| personality.attributes.symbolize_keys } unless @personality_hashes.present?
    raise 'invalid parameter' unless @personality_hashes.present?

    @user = User.find_by(id: params[:user_id])
    raise 'invalid user id' unless @user.present?

    @journey_hash = Journey.fetch_journey_hash_by_id(params[:journey_id])
    raise 'invalid journey id' unless @journey_hash.present?
    raise 'journey is already prepared' unless Journey.preparing?(@journey_hash)
  end
end
