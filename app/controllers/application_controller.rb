class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def get_user_info_from_request
    @user = User.find_by(id: params[:user_id])
    raise 'user not founded' unless @user.present?
  end
end
