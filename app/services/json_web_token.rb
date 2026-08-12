class JsonWebToken
  ALGORITHM = "HS256"
  DEFAULT_EXPIRY = 24.hours

  class << self
    def encode(payload, exp: DEFAULT_EXPIRY.from_now)
      JWT.encode(payload.merge(exp: exp.to_i), secret, ALGORITHM)
    end

    def decode(token)
      body, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError
      nil
    end

    private

    def secret
      Rails.application.secret_key_base
    end
  end
end
