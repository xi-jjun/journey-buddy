class KakaoLoginService
  include KakaoApiRequestManager

  def kakaotalk_login_redirect_url
    kakao_login_url
  end

  def request_to_kakao_api_for_login(code)
    access_token = request_for_token(code)
    email = request_for_user_email(access_token)

    user = User.find_by(email: email)
    user = User.create!(email: email, password: SecureRandom.hex(10)) unless user.present?

    { user_hash: user.attributes.symbolize_keys.except(:encrypted_password), redirect_url: kakao_login_redirect_url }
  end
end
