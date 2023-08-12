class Api::V1::Users::UserController < ApplicationController
  before_action :validate_jwt, except: :sign_up # 순서 바꾸면 에러 발생
  before_action :check_user, except: :sign_up
  before_action :set_profile_image, only: [:sign_up, :update_info]

  def sign_up
    user = User.new(email: params[:email], password: params[:password], profile_image_url: params[:profile_image_url], name: params[:name], nickname: params[:nickname])
    user.login_platform = User::LoginPlatform::DEFAULT
    user.status = User::Status::ACTIVE

    user.save!
    user_hash = user.attributes.symbolize_keys
    token = @jwt_service.generate_jwt(user_hash)

    render json: { code: 200, token: token }
  rescue StandardError => e
    Rails.logger.error("fail sign_up api error #{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: '회원가입에 실패하셨습니다.', token: '' }, status: :bad_request
  end

  def details
    user_hash = @user.attributes.symbolize_keys
    user_hash.delete(:encrypted_password)
    render json: { code: 200, user: user_hash }
  rescue StandardError => e
    Rails.logger.warn("fail details api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  def update_info
    @user.update(params)
    updated_user_hash = @user.attributes.symbolize_keys
    updated_user_hash.delete(:encrypted_password)

    render json: { code: 200, message: 'success', updated_user: updated_user_hash }
  rescue StandardError => e
    Rails.logger.warn("fail update_info api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  private

  def set_profile_image
    if params[:profile_image_url].present?
      file = params[:profile_image_url]
      file_info = { file: file, extension: File.extname(file.original_filename) }

      params[:profile_image_url] = S3BucketManager.upload_file_to_s3(file_info)[:file_url]
    end
  end

  def check_user
    render json: { code: 400, message: '잘못된 요청입니다. (일치하지 않는 사용자)' }, status: :unauthorized unless params[:user_id].to_i == @user.id
  end
end
