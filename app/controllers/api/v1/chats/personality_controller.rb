class Api::V1::Chats::PersonalityController < ApplicationController
  before_action :validate_and_set_personality_params, only: [:chat_role_setting]

  def chat_role_list
    personalities = Personality.select(:id, :display_name).all.map(&:as_json)

    render json: { code: 200, personalities: personalities }
  end

  def chat_role_setting
    @personalities.each do |personality|
      BuddyPersonality.create!(personality_id: personality[:id], journey_id: @journey[:id])
      Chat.create!(writer: Chat::Writer::SYSTEM,
                   content: personality[:description],
                   content_type: Chat::ContentType::TEXT,
                   journey_id: @journey[:id],
                   user_id: @user[:id])
    end
    prepared_journey = Journey.find_by(id: @journey[:id])
    prepared_journey.update!(status: Journey::Status::TRAVELING)

    render json: { code: 200, message: 'success' }
  rescue StandardError => e
    Rails.logger.error("fail to chat_role_setting api error=#{e.message}")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  private

  def validate_and_set_personality_params
    personality_ids = params[:personalities].split(',').map(&:to_i)
    @personalities = Rails.cache.read_multi(*personality_ids, raw: true)
    raise 'invalid parameter' unless @personalities.present?

    @user = User.find_by(id: params[:user_id]).attributes.symbolize_keys
    raise 'invalid user id' unless @user.present?

    @journey = Journey.fetch_journey_hash_by_id(params[:journey_id])
    raise 'invalid journey id' unless @journey.present?
    raise 'journey is already prepared' unless Journey.preparing?(@journey)
  end
end
