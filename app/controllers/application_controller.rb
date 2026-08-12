class ApplicationController < ActionController::API
  include Authenticatable
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def user_json(user)
    { id: user.id, email: user.email, role: user.role }
  end

  def render_forbidden
    render json: { error: "Forbidden", message: "You are not authorized to access this resource."
                 }, status: :forbidden
  end
end
