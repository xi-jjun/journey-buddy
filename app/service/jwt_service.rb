require 'jwt'

class JwtService
  SECRET_KEY = ENV['JWT_SECRET_KEY']
  HS256_ALGORITHM = 'HS256'

  def generate_jwt(user_hash)
    payload = { user_id: user_hash[:id], email: user_hash[:email], expired_at: Time.now + 24.hours }
    JWT.encode(payload, SECRET_KEY, HS256_ALGORITHM)
  end

  def valid_jwt?(token)
    raise 'empty token' unless token.present?

    decoded_token = JWT.decode(token, SECRET_KEY, true, { algorithm: HS256_ALGORITHM })
    payload = decoded_token[0].symbolize_keys
    raise 'empty payload' unless payload.present?

    user = User.find_by(id: payload[:user_id])
    raise 'user not founded' unless user.present?

    now = Time.now
    token_expired_at = payload[:expired_at]
    raise 'expired token' unless now <= token_expired_at

    { result: true, user: user }
  rescue StandardError => e
    Rails.logger.warn("invalid jwt error=#{e.message} | backtrace=#{e.backtrace}")
    { result: false, user: user }
  end
end
