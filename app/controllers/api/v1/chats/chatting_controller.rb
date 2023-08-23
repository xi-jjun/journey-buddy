class Api::V1::Chats::ChattingController < ApplicationController
  before_action :validate_jwt, only: [:send_chat]
  before_action :set_params_for_chat, only: [:send_chat]

  module FileType
    IMAGE = '사진'
    VOICE = '소리'
    VIDEO = '영상'
  end

  def get_all_chats
    # chats = Chat.fetch_all_chats_by_journey_id(@journey.id)
    @journey = Journey.includes(:buddy).find_by(id: params[:journey_id])
    result = Oj.dump(Chat.where(journey_id: @journey.id).map(&:as_json))
    chats = result.present? ? Oj.load(result, symbol_keys: true) : []

    buddy_name = @journey.buddy.name
    buddy_profile_image = @journey.buddy.profile_image_url
    chats.each do |chat|
      chat[:buddy_name] = buddy_name if chat[:writer] == Chat::Writer::ASSISTANT
      chat[:buddy_profile_image] = buddy_profile_image
      chat[:created_at] = chat[:created_at].to_datetime.strftime('%p %I:%M')
    end

    render json: { code: 200, chats: chats }
  rescue StandardError => e
    Rails.logger.error("fail get_all_chats api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  def send_chat
    if @content == '/여행끝'
      @journey.update!(status: Journey::Status::COMPLETED)
      Chat.create!(writer: Chat::Writer::USER, content: @content, content_type: Chat::ContentType::TEXT, journey_id: @journey.id, user_id: @user.id, latitude: @latitude, longitude: @longitude)
      Chat.create!(writer: Chat::Writer::ASSISTANT, content: '함께 여행해서 즐거웠어! 다음에 또 보자', content_type: Chat::ContentType::TEXT, journey_id: @journey.id, user_id: @user.id)
      render json: { code: 200 }
      return
    end

    # chat_context = Chat.fetch_all_chats_by_journey_id(@journey.id)
    result = Oj.dump(Chat.where(journey_id: @journey.id).map(&:as_json))
    chat_context = result.present? ? Oj.load(result, symbol_keys: true) : []

    user_send_chat = { writer: @chat_role, content: @content }
    chat_context << user_send_chat

    answer = if @content_type == Chat::ContentType::TEXT
               ChatGptApiManager.request_answer_to_chat_gpt(chat_context)
             else
               "이 #{file_type_name}멋진걸? 좋은 추억으로 간직할 수 있도록 보관해둘게!"
             end
    raise 'empty gpt answer' unless answer.present?

    gpt_chat = { writer: Chat::Writer::ASSISTANT, content: answer }
    chat_context << gpt_chat

    user_chat = ''
    buddy_chat = ''
    ActiveRecord::Base.transaction do
      user_chat = Chat.create!(writer: user_send_chat[:writer], content: user_send_chat[:content], content_type: @content_type.to_i, journey_id: @journey.id, user_id: @user.id, latitude: @latitude, longitude: @longitude)
      buddy_chat = Chat.create!(writer: gpt_chat[:writer], content: gpt_chat[:content], content_type: Chat::ContentType::TEXT, journey_id: @journey.id, user_id: @user.id)
    end

    question = user_chat.attributes.symbolize_keys
    buddy_answer = buddy_chat.attributes.symbolize_keys
    # Chat.write_cache_for_user_journey_chats_by_journey_id(params[:journey_id], chat_context)

    render json: { code: 200, question: question, answer: buddy_answer }
  rescue StandardError => e
    Rails.logger.error("fail to answer user question error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  private

  def set_params_for_chat
    @journey = Journey.find_by(user_id: @user.id, status: Journey::Status::TRAVELING)
    @chat_role = params[:chat_role].to_i
    @content_type = params[:content_type].to_i
    @content = if @content_type == Chat::ContentType::TEXT
                 params[:content]
               elsif Chat::ContentType::IMAGE || Chat::ContentType::VOICE
                 @file_type = file_type_name
                 set_upload_file_and_get_content
               else
                 raise 'invalid content type'
               end
    @latitude = params[:lat]
    @longitude = params[:lng]
  end

  def set_upload_file_and_get_content
    file = params[:content]
    file_info = { file: file, extension: File.extname(file.original_filename) }
    result = S3BucketManager.upload_file_to_s3(file_info)

    result[:file_url]
  end

  # draper 로 옮기기?
  def file_type_name
    case @content_type
    when Chat::ContentType::IMAGE
      FileType::IMAGE
    when Chat::ContentType::VOICE
      FileType::VOICE
    when Chat::ContentType::VIDEO
      FileType::VIDEO
    else
      ''
    end
  end
end
