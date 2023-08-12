class Api::V1::Journeys::JourneyController < ApplicationController
  before_action :validate_jwt, only: [:start_journey]

  # 여행 시작 API
  def start_journey
    @user_hash = @user.attributes.symbolize_keys
    raise '이미 진행중이거나 준비중인 여행이 존재합니다.' if already_traveling_or_preparing?

    # 동행AI 결정
    buddy_id = select_buddy

    # 여행 생성 - 준비중 상태 (아직 타이틀 정보를 기입하지 않았기 때문)
    journey = Journey.create!(status: Journey::Status::PREPARING, user_id: @user_hash[:id], buddy_id: buddy_id)
    render json: { code: 200, message: 'success', journey_id: journey.id }
  rescue StandardError => e
    Rails.logger.error("fail start_journey api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  def journey_detail
    raise 'invalid parameter' unless params[:journey_id].present?

    @journey = Journey.fetch_journey_hash_by_id(params[:journey_id])
    raise 'journey not founded' unless @journey.present?

    render json: { code: 200, journey: @journey }
  rescue StandardError => e
    Rails.logger.warn("fail journey_detail api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  def check_traveling
    @journey = Journey.where(user_id: params[:user_id], status: [Journey::Status::PREPARING, Journey::Status::TRAVELING]).first
    render json: { code: 200, traveling: @journey.present? }
  end

  def journey_status_update
    raise 'invalid parameter' unless Journey.valid_status?(params[:status].to_i)
    raise 'invalid parameter' unless params[:journey_id].present?

    @journey = Journey.find_by(id: params[:journey_id])
    @journey.update!(status: params[:status])
    render json: { code: 200, message: 'success' }
  end

  private

  def already_traveling_or_preparing?
    Journey.where(user_id: @user_hash[:id], status: [Journey::Status::PREPARING, Journey::Status::TRAVELING]).present?
  end

  # @return 동행 AI id
  def select_buddy
    # 동행AI 결정
    select_point = 0
    @user.personalities.each do |user_personality|
      select_point += 1 if user_personality.id % 2 == 0
      select_point -= 1 if user_personality.id % 2 == 1
    end

    # TODO : 동행 AI 를 결정하는 로직인데, 일단은 이렇게 해두고 나중에 개발예정
    if select_point > 0
      params[:gender] % 2 == 1 ? 1 : 2 # male : woman
    else
      params[:gender] % 2 == 1 ? 3 : 4
    end
  end
end
