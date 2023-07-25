class Api::V1::Journeys::JourneyController < ApplicationController
  def start_journey
    Journey.create!(title: params[:title], status: Journey::Status::PREPARING, user_id: params[:user_id])
    render json: { code: 200, message: 'success' }
  rescue StandardError => e
    Rails.logger.error("ready_to_journey api fail")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  def journey_detail
    raise 'invalid parameter' unless params[:journey_id].present?

    @journey = Journey.fetch_journey_hash_by_id(params[:journey_id])
    raise 'journey not founded' unless @journey.present?

    render json: { code: 200, journey: @journey }
  rescue StandardError => e
    Rails.logger.warn("journey_detail api fail")
    render json: { code: 400, message: 'fail' }, status: :bad_request
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
