class Api::V1::Users::JourneyController < ApplicationController
  # before_action :validate_jwt, only: [:user_journey_history_detail]

  def total_user_journey
    raise 'invalid parameter' unless params[:user_id].present?

    journeys = Journey.where(user_id: params[:user_id])
    journey_hashes = journeys.map { |journey| journey.attributes.symbolize_keys }
    journey_hashes.each do |journey_hash|
      # 여행의 대표 사진은 채팅내용의 첫번째 이미지
      journey_hash[:image_url] = Chat.where(journey_id: journey_hash[:id], content_type: Chat::ContentType::IMAGE)&.first&.content
      journey_hash[:created_at] = journey_hash[:created_at].to_datetime.strftime('%Y.%m.%d')
    end

    render json: { code: 200, journeys: journey_hashes }
  rescue StandardError => e
    Rails.logger.error("fail total_user_journey api error=#{e.message} | backtrace=#{e.backtrace&.slice(0, 5)}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  def user_journey_history_detail
    raise 'invalid parameter' unless params[:journey_id].present?

    journey = Journey.includes(:chats).find_by(id: params[:journey_id])
    raise '잘못된 사용자입니다.' unless journey.user_id == params[:user_id].to_i

    result = Oj.dump(journey.chats.map(&:as_json))
    chat_hashes = result.present? ? Oj.load(result, symbol_keys: true) : []

    # 채팅 생성
    # - AI 프로필 정보를 위해서 buddy 조회
    # - created_at 이름을 그대로 프론트에서 쓰기에, 총 걸린 시간은 미리 구함
    buddy_name = journey.buddy.name
    buddy_profile_image = journey.buddy.profile_image_url
    total_spend_time = ((chat_hashes.last[:created_at].to_time - chat_hashes[0][:created_at].to_time) / 1.minute).to_i
    chat_hashes.each do |chat_hash|
      chat_hash[:buddy_name] = buddy_name if chat_hash[:writer] == Chat::Writer::ASSISTANT
      chat_hash[:buddy_profile_image] = buddy_profile_image
      chat_hash[:created_at] = chat_hash[:created_at].to_datetime.strftime('%p %I:%M')
    end

    response_data = {}
    if chat_hashes.length > 0
      response_data[:journey_title] = journey.title
      response_data[:journey_subtitle] = '' # TODO : migration --> 유저입력?
      response_data[:journey_location] = '위치' # TODO : 방법찾아야 함
      response_data[:total_chat_cnt] = chat_hashes.length
      response_data[:total_spend_time] = total_spend_time
      response_data[:total_distance] = 1324 # TODO : 방법찾아야 함
      response_data[:chats] = chat_hashes
    end

    render json: { code: 200, result: response_data }
  rescue StandardError =>e
    Rails.logger.error("fail user_journey_history_detail api error=#{e.message} | info=#{response_data}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end
end
