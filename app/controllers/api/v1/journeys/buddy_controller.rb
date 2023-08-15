class Api::V1::Journeys::BuddyController < ApplicationController
  before_action :validate_jwt

  def buddy_detail
    raise 'invalid parameter' unless params[:journey_id].present?

    journey = Journey.find_by(id: params[:journey_id])
    raise '해당 사용자와 일치하지 않는 여행정보 입니다.' unless journey.user_id == @user.id
    raise '해당 여행정보를 찾을 수 없습니다.' unless journey.present?

    buddy = journey.buddy
    raise '동행AI 정보가 존재하지 않습니다.' unless buddy.present?

    buddy_hash = buddy.attributes.symbolize_keys
    puts "buddy info : #{buddy_hash}"

    render json: { code: 200, buddy: buddy_hash }
  rescue StandardError => e
    Rails.logger.error("fail buddy_detail api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, buddy: '', message: e.message }, status: :bad_request
  end
end
