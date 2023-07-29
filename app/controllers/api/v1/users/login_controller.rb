class Api::V1::Users::LoginController < ApplicationController
  before_action :load_jwt_service

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
end
