class Api::V1::Chats::BuddySettingController < ApplicationController
  before_action :get_user_info_from_request, only: [:init_user_buddy_settings]
  before_action :set_api_params, only: :init_user_buddy_settings

  # 어드민 기능에 가까운 동행 AI 인격 생성 API
  # @param [String] buddy_name 동행AI 이름
  # @param [String] buddy_display_name (Optional) 동행AI 노출시킬 이름
  # @param [String] buddy_gender 동행AI 성별
  # @param [Integer] buddy_age 동행AI 나이
  # @param [String] buddy_display_description 동행AI 설명서(사용자에게 선택을 위해 노출하는 용도)
  # @param [String] buddy_description 동행AI 역할 설정 스크립트(Chat GPT API에 사용)
  def create_buddy
    # 일단은 아래 스크립트로 생성하는 것으로..
    # Buddy.create!(name: '테스트 AI 1', profile_image_url: 'https://hotpotmedia.s3.us-east-2.amazonaws.com/8-TZgIyxxiX2Dn4Lr.png?nc=1', gender: 1, age: 25, display_description: '남자 25살 동행AI, 잘 챙겨주는 다정한성격', description: '당신은 사람들의 여행 동반자 역할을 입니다. 당신은 올해로 25살입니다. 당신은 남자입니다. 당신은 사람들을 잘 챙겨줍니다. 당신은 다정한 성격입니다. 당신은 친구가 여행갈 때 빠트린 것은 없는지 확인을 하는 성격입니다.')
  end

  # 여행 시작 전(준비중)인 상황에서 사용자 성향기반으로 동행AI의 역할 설정을 하기 위한 API
  # 해당 여행의 첫번째 System Chat을 생성
  # 부가설명 : 사용자가 고른 성향에 맞게 buddy를 배정해야 함. --> 프론트에서 해주기로 함.
  #          서버에서는 그냥 DB에 극명한 4개의 AI를 만들어 놓으면 됨. (보여주는게 달라야 하기 때문)
  # @param [Integer] user_id 사용자 id
  # @param [Integer] buddy_id 동행AI id
  # @param [Integer] journey_id 여행 id
  def init_user_buddy_settings
    raise '이미 진행중이거나 완료된 여행입니다' unless @journey_hash[:status] == Journey::Status::PREPARING

    system_chat = ""
    system_chat << @buddy_hash[:description] << "\n"
    @user_personalities.each do |user_personaltiy|
      system_chat << user_personaltiy.description << "\n"
    end

    Chat.create!(writer: Chat::Writer::SYSTEM, content: system_chat, content_type: Chat::ContentType::TEXT, journey_id: @journey_hash[:id], user_id: @user.id)
    Journey.find_by(id: @journey_hash[:id]).update!(status: Journey::Status::TRAVELING) # 동행AI 성격을 설정하면 여행준비 끝

    render json: { code: 200, message: 'success' }
  rescue StandardError => e
    Rails.logger.warn("fail init_buddy_settings_by_user_personalities api error=#{e.message}|backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  private

  def set_api_params
    @user_personalities = @user.personalities
    raise '사용자의 성향이 존재하지 않습니다.' unless @user_personalities.present?

    @buddy_hash = Buddy.fetch_buddy_hash_by_id(params[:buddy_id])
    raise '해당하는 동행AI 정보가 존재하지 않습니다.' unless @buddy_hash.present?

    @journey_hash = Journey.fetch_journey_hash_by_id(params[:journey_id])
    raise '해당하는 여행정보가 존재하지 않습니다.' unless @journey_hash.present?
  end
end
