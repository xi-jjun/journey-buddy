class Api::V1::Users::LoginController < ApplicationController
  before_action :load_jwt_service
  before_action :load_kakao_login_service, only: [:kakao_login_url, :kakao_login_callback]

  # @param [String] email
  # @param [String] password
  def user_login
    user = User.find_by(email: params[:email])
    raise '존재하지 않는 이메일 입니다.' unless user.present?
    raise '비밀번호가 일치하지 않습니다.' unless user.valid_password?(params[:password])

    user_hash = user.attributes.symbolize_keys
    token = @jwt_service.generate_jwt(user_hash)

    render json: { code: 200, token: token }
  rescue StandardError => e
    render json: { code: 400, message: e.message }, status: :bad_request
  end

  def kakao_login_url
    redirect_to @kakao_login_service.kakaotalk_login_redirect_url, allow_other_host: true
  end

  def kakao_login_callback
    code = params[:code]
    user_hash = @kakao_login_service.request_to_kakao_api_for_login(code)
    token = @jwt_service.generate_jwt(user_hash)

    redirect_to "http://localhost:3000?token=#{token}", allow_other_host: true
  end

  private

  def load_kakao_login_service
    @kakao_login_service ||= KakaoLoginService.new
  end
end
