module AuthHelpers
  def create_user(attrs = {})
    role = attrs.fetch(:role, :admin)
    defaults = {
      email: "#{role}@example.com",
      password: "password123",
      role: role
    }
    defaults[:payout_rate] = 0.8 if role.to_s == "client"
    User.create!(defaults.merge(attrs))
  end

  def auth_headers(user, exp: JsonWebToken::DEFAULT_EXPIRY.from_now)
    token = JsonWebToken.encode({ sub: user.id, role: user.role }, exp: exp)
    { "Authorization" => "Bearer #{token}" }
  end

  def json_body
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
