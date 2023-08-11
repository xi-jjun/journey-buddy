require 'net/http'
require 'uri'
require 'oj'

module RequestManager
  private

  def get_request(request_url, query_params: nil)
    request_url = request_url.force_encoding("UTF-8")
    uri = URI(request_url)
    uri.query = URI.encode_www_form(query_params) if query_params.present?

    response = Net::HTTP.get_response(uri)
    response_body_hash = Oj.load(response.body, symbol_keys: true)
    raise '빈 API 응답값입니다.' unless response_body_hash.present?

    response_body_hash[:response][:body]
  rescue StandardError => e
    Rails.logger.error("fail get_request from #{request_url} | error=#{e.message} | backtrace=#{e.backtrace}")
    {}
  end
end
