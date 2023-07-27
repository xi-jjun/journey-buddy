class Api::V1::Quests::QuestController < ApplicationController
  before_action :set_quest_api_params, except: :complete_mission

  VALID_EXTENSION_NAME = ['.jpg', '.jpeg', '.mp4', '.png', '.mp3']

  def generate_random_mission
    # 해당 유저에게 추천되는 퀘스트는 여행 단위로 중복을 검증
    already_assigned_quest_ids = Mission.where(user_id: @user[:id], journey_id: @journey[:id]).pluck(:quest_id)
    quest_hashes = Quest.where.not(id: already_assigned_quest_ids).map { |quest| quest.attributes.symbolize_keys }
    raise 'no avaliable quest' unless quest_hashes.present?

    random_num = rand(quest_hashes.length)
    quest_mission_hash = quest_hashes[random_num]

    Mission.create!(user_id: @user[:id], quest_id: quest_mission_hash[:id], journey_id: @journey[:id], status: Mission::Status::ON_GOING)

    render json: {
      code: 200,
      mission: mission_info(quest_mission_hash)
    }
  rescue StandardError => e
    Rails.logger.warn("fail generate_random_mission api error=#{e.message}")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  def user_missions
    query = Mission.includes(:quest)
                   .includes(quest: :reward_badge)
                   .where(user_id: @user[:id], journey_id: @journey[:id])
    query = query.where(status: params[:status]) if params[:status].present?
    @user_mission_hashes = query.map { |mission| mission_list_info(mission) }

    render json: { code: 200, missions: @user_mission_hashes }
  rescue StandardError => e
    Rails.logger.warn("fail user_mission api error=#{e.message}|backtrace=#{e.backtrace.slice(0, 10)}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  def reject_mission
    mission = Mission.find_by(params[:mission_id])
    raise 'not user mission' unless @user[:id].to_i == mission.user_id

    mission.update!(status: Mission::Status::REJECTED)

    render json: { code: 200, message: 'success' }
  rescue StandardError => e
    Rails.logger.warn("fail reject_mission api error=#{e.message}")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  # @param [String] user_chat_content 사용자의 미션 인증 채팅(텍스트/사진/음성/영상)
  # @param [Integer] content_type 사용자 채팅내용의 타입(TEXT/IMAGE/VOICE/VIDEO)
  # @param [Integer] mission_id 완료 인증할 사용자의 미션
  # @param [Float] latitude TODO : 구현 전이라 구현은 나중에
  # @param [Float] longitude TODO : 구현 전이라 구현은 나중에
  def complete_mission
    mission = Mission.find_by(id: params[:mission_id])
    user_chat = { writer: Chat::Writer::USER, content: params[:user_chat_content] }
    gpt_chat = { writer: Chat::Writer::SYSTEM, content: '인증받기는 어렵겠는걸?ㅠ' } # gpt 대신 하드코딩으로 대신 답변 --> role : system인 이유

    # 완료인증을 받으면 gpt 답변문구 변경
    if check_complete(params[:user_chat_content])
      mission.update!(status: Mission::Status::COMPLETED, completed_at: Time.now)
      gpt_chat[:content] = '미션 성공! 고생많았어~!'
    end

    ActiveRecord::Base.transaction do
      Chat.create!(writer: user_chat[:writer], content: user_chat[:content], content_type: params[:content_type], journey_id: mission.journey_id, user_id: mission.user_id, latitude: params[:latitude], longitude: params[:longitude])
      Chat.create!(writer: gpt_chat[:writer], content: gpt_chat[:content], content_type: Chat::ContentType::TEXT, journey_id: mission.journey_id, user_id: mission.user_id, latitude: params[:latitude], longitude: params[:longitude])
    end

    # 캐시 갱신
    @chat_context = Chat.fetch_all_chats_by_journey_id(mission.journey_id, force: true)

    render json: { code: 200, answer: gpt_chat[:content], completed: mission.status == Mission::Status::COMPLETED }
  rescue StandardError => e
    Rails.logger.warn("fail complete_mission api")
    render json: { code: 400, message: 'fail' }, status: :bad_request
  end

  private

  def set_quest_api_params
    @user = User.find_by(id: params[:user_id]).attributes.symbolize_keys
    raise 'invalid parameter' unless @user.present?

    @journey = Journey.fetch_journey_hash_by_id(params[:journey_id])
    raise 'invalid parameter' unless @journey.present?
  end

  def mission_info(quest_hash)
    reward_badge_hash = RewardBadge.fetch_reward_badge_hash_by_id(quest_hash[:reward_badge_id])
    {
      title: quest_hash[:title],
      content: quest_hash[:content],
      reward_badge: {
        name: reward_badge_hash[:name],
        image_url: reward_badge_hash[:image_url]
      }
    }
  end

  def check_complete(content)
    # TODO : 나중에 시간되면 완료확인 로직 필요
    file = content
    extension = File.extname(file.original_filename)

    VALID_EXTENSION_NAME.include?(extension)
  end

  # @param [Mission] mission 미션 active record 객체
  def mission_list_info(mission)
    {
      title: mission.quest.title,
      content: mission.quest.content,
      completed: mission.status == Mission::Status::COMPLETED,
      completed_at: mission.completed_at,
      reward_badge: mission.quest.reward_badge.image_url
    }
  end
end
