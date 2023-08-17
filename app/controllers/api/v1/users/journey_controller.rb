class Api::V1::Users::JourneyController < ApplicationController
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
    render json: { code: 400, message: e.message }
  end
end
