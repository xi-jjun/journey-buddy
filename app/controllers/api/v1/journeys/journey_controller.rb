class Api::V1::Journeys::JourneyController < ApplicationController
  def start_journey
    raise '이미 진행중이거나 준비중인 여행이 존재합니다.' if Journey.where(user_id: params[:user_id], status: [Journey::Status::PREPARING, Journey::Status::TRAVELING]).present?

    journey = Journey.create!(title: params[:title], status: Journey::Status::PREPARING, user_id: params[:user_id])
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
end
