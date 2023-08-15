class Api::V1::Journeys::BuddyController < ApplicationController
  before_action :validate_jwt
  before_action :set_resource_for_init_setting, only: :journey_buddy_init_setting

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

  # 여행의 동행AI의 초기 세팅을 위한 API
  # - 채팅을 위해서 역할 설정을 해준다.
  # - 이 때에 Journey 의 상태는 '여행중'이 된다.
  def journey_buddy_init_setting
    # 1. 해당 Buddy 의 description 정보를 Chat GPT 에게 보내기 위해 스크립트 생성
    # 2. 유저의 성향정보를 가져와서 Chat GPT 에게 보내기 위해 스크립트 생성
    # 3. 스크립트로 SYSTEM 속성의 채팅 생성
    system_chat = ""
    system_chat << "#{@buddy_hash[:description]}\n"
    @user_personality_hashes.each { |user_personality_hash| system_chat << "#{user_personality_hash[:description]}\n" }

    # AI 채팅에는 위치정보를 넣지 않는다. (프론트에서 마커로 표현 시 겹치기 때문에 사실상 쓸모가 없기 때문)
    Chat.create!(writer: Chat::Writer::SYSTEM, content: system_chat, content_type: Chat::ContentType::TEXT, journey_id: @journey_hash[:id], user_id: @user.id)
    @journey.update!(status: Journey::Status::TRAVELING) # 채팅을 위한 동행AI 역할이 설정되면, 여행은 '여행중' 상태로 변경된다.

    render json: { code: 200 }
  rescue StandardError => e
    Rails.logger.error("fail journey_buddy_init_setting api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  private

  def set_resource_for_init_setting
    @journey = Journey.find_by(id: params[:journey_id])
    raise '해당 여행정보를 찾을 수 없습니다.' unless @journey.present?

    @journey_hash = @journey.attributes.symbolize_keys
    raise '해당 사용자와 일치하지 않는 여행정보 입니다.' unless @journey_hash[:user_id] == @user.id

    @buddy_hash = @journey.buddy.attributes.symbolize_keys
    raise '동행AI 정보가 존재하지 않습니다.' unless @buddy_hash.present?

    user_personalities = @user.personalities
    raise '성향 테스트가 정보가 존재하지 않습니다.' unless user_personalities.present?

    @user_personality_hashes = user_personalities.map { |user_personality| user_personality.attributes.symbolize_keys }
  end
end
