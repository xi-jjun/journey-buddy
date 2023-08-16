class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :load_jwt_service

  def get_user_info_from_request
    @user = User.find_by(id: params[:user_id])
    raise 'user not founded' unless @user.present?
  end

  def validate_jwt
    token = request.headers[:Authorization]
    result = @jwt_service.valid_jwt?(token)
    @user = result[:user]
    raise '인증에 실패했습니다.' unless result[:result] == true
  end

  private

  def load_jwt_service
    @jwt_service ||= JwtService.new
  end
end
