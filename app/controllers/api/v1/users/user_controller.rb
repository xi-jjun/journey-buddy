class Api::V1::Users::UserController < ApplicationController
  before_action :validate_jwt, except: :sign_up # 순서 바꾸면 에러 발생
  before_action :check_user, except: :sign_up

  def sign_up
    user = User.new(user_resource)
    user.login_platform = User::LoginPlatform::DEFAULT
    user.status = User::Status::ACTIVE

    user.save!

    render json: { code: 200, user_id: user.id }
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
    @user.update(user_resource)
    updated_user_hash = @user.attributes.symbolize_keys
    updated_user_hash.delete(:encrypted_password)

    render json: { code: 200, message: 'success', updated_user: updated_user_hash }
  rescue StandardError => e
    Rails.logger.warn("fail update_info api error=#{e.message} | backtrace=#{e.backtrace}")
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  private

  def user_resource
    params.permit(:email, :password, :profile_image_url, :nickname, :status)
  end

  def check_user
    render json: { code: 400, message: '잘못된 요청입니다.프 (일치하지 않는 사용자)' }, status: :unauthorized unless params[:user_id].to_i == @user.id
  end
end
