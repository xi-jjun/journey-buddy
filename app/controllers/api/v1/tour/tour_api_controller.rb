class Api::V1::Tour::TourApiController < ApplicationController
  include RequestManager
  SERVICE_API_KEY = ENV['TOUR_SERVICE_API_KEY']

  def tour_list_by_geoloaction
    base_url = "https://apis.data.go.kr/B551011/KorService1/locationBasedList1"
    query_params = {
      MobileOS: 'ETC',
      MobileApp: 'JourneyBuddy',
      numOfRows: 20,
      mapX: params[:lng].to_f,
      mapY: params[:lat].to_f,
      radius: params[:radius].to_i,
      serviceKey: SERVICE_API_KEY,
      _type: 'json'
    }
    # 관광타입(12:관광지, 14:문화시설, 15:축제공연행사, 25:여행코스, 28:레포츠, 32:숙박, 38:쇼핑, 39:음식점) ID
    query_params[:contentTypeId] = params[:tour_content_type_id] if params[:tour_content_type_id].present?

    response_body_hash = get_request(base_url, query_params: query_params)
    raise 'empty tour list response' unless response_body_hash.present?

    tour_hashes = response_body_hash[:items].present? ? response_body_hash[:items][:item] : []

    render json: { tour_list: tour_hashes }
  rescue StandardError => e
    Rails.logger.error("fail tour_list_by_geoloaction api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { tour_list: [] }, status: :bad_request
  end
end
