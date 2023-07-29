class Api::V1::Chats::ChattingController < ApplicationController
  before_action :set_params_for_chat, only: [:get_all_chats, :send_chat]

  module FileType
    IMAGE = '사진'
    VOICE = '소리'
    VIDEO = '영상'
  end

  def get_all_chats
    chats = Chat.fetch_all_chats_by_journey_id(@journey.id)
    render json: { code: 200, chats: chats }
  rescue StandardError => e
    Rails.logger.error("get_all_chats error")
    render json: { code: 400, message: 'fail to load chats' }, status: :bad_request
  end

  def send_chat
    chat_context = Chat.fetch_all_chats_by_journey_id(@journey.id)

    user_chat = { writer: @chat_role, content: @content }
    chat_context << user_chat

    answer = if @content_type == Chat::ContentType::TEXT
               ChatGptApiManager.request_answer_to_chat_gpt(chat_context)
             else
               "이 #{file_type_name}멋진걸? 좋은 추억으로 간직할 수 있도록 보관해둘게!"
             end
    raise 'empty gpt answer' unless answer.present?

    gpt_chat = { writer: Chat::Writer::ASSISTANT, content: answer }
    chat_context << gpt_chat

    ActiveRecord::Base.transaction do
      Chat.create!(writer: user_chat[:writer], content: user_chat[:content], content_type: @content_type.to_i, journey_id: @journey.id, user_id: @user.id, latitude: @latitude, longitude: @longitude)
      Chat.create!(writer: gpt_chat[:writer], content: gpt_chat[:content], content_type: Chat::ContentType::TEXT, journey_id: @journey.id, user_id: @user.id, latitude: @latitude, longitude: @longitude)
    end

    Chat.write_cache_for_user_journey_chats_by_journey_id(params[:journey_id], chat_context)

    render json: { code: 200, answer: answer }
  rescue StandardError => e
    Rails.logger.error("fail to answer user question error_message=#{e.message}, answer=#{answer}")
    render json: { code: 400, message: 'send_chat error' }, status: :bad_request
  end

  private

  def set_params_for_chat
    @journey = Journey.find_by(id: params[:journey_id])
    @user = User.find_by(id: params[:user_id])
    @chat_role = params[:chat_role].to_i
    @content_type = params[:content_type].to_i
    @content = case @content_type
               when Chat::ContentType::TEXT
                 params[:content]
               when Chat::ContentType::IMAGE || Chat::ContentType::VOICE
                 @file_type = set_file_type
                 set_upload_file_and_get_content
               else
                 ''
               end
    @latitude = params[:latitude]
    @longitude = params[:longitude]
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
