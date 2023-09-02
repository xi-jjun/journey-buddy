require 'net/http'
require 'oj'

module KakaoApiRequestManager
  REST_API_KEY = ENV['KAKAOTALK_REST_API_KEY']
  LOGIN_CALLBACK_URI = ENV['KAKAOTALK_LOGIN_CALLBACK_URI']
  REDIRECT_URL = ENV['KAKAOTALK_LOGIN_REDIRECT_URL']

  private

  def kakao_login_url
    "https://kauth.kakao.com/oauth/authorize?response_type=code&client_id=#{REST_API_KEY}&redirect_uri=#{LOGIN_CALLBACK_URI}"
  end

  def kakao_login_redirect_url
    REDIRECT_URL
  end

  def request_for_token(code)
    url = URI.parse('https://kauth.kakao.com/oauth/token')

    data = { grant_type: 'authorization_code', client_id: REST_API_KEY, redirect_uri: LOGIN_CALLBACK_URI, code: code }.stringify_keys

    request = Net::HTTP::Post.new(url.path)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.form_data = data

    response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
      http.request(request)
    end

    response_body_hash = Oj.load(response.body, symbol_keys: true)
    raise '인증에 실패하였습니다.' unless response_body_hash[:access_token].present?

    response_body_hash[:access_token]
  rescue StandardError => e
    Rails.logger.warn("fail request_for_token error=#{e.message} | backtrace=#{e.backtrace}")
    ''
  end

  def request_for_user_email(access_token)
    url = URI.parse('https://kapi.kakao.com/v2/user/me')

    request = Net::HTTP::Get.new(url.path)
    request['Authorization'] = "Bearer #{access_token}"

    response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
      http.request(request)
    end

    response_body_hash = Oj.load(response.body, symbol_keys: true)
    raise '이메일 정보를 가져오는 것에 실패하였습니다.' unless response_body_hash[:kakao_account].present?

    response_body_hash[:kakao_account][:email]
  rescue StandardError => e
    Rails.logger.warn("fail request_for_user_email error=#{e.message} | backtrace=#{e.backtrace}")
    ''
  end
end
