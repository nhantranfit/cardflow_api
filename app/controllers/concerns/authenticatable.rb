module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  private

  attr_reader :current_user

  def authenticate_request!
    token = bearer_token
    return render_unauthorized("Missing token") if token.blank?

    payload = JsonWebToken.decode(token)
    @current_user = User.find_by(id: payload[:sub]) if payload
    render_unauthorized("Invalid or expired token") unless @current_user
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    scheme, token = header.split(" ", 2)
    token if scheme&.casecmp("Bearer")&.zero?
  end

  def render_unauthorized(message)
    render json: {
      error: "Unauthorized",
      message: message
    }, status: :unauthorized
  end
end
