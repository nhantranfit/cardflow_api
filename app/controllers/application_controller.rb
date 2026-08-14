class ApplicationController < ActionController::API
  include Authenticatable
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found


  private

  def user_json(user)
    { id: user.id, email: user.email, role: user.role }
  end

  def render_forbidden
    render json: {
      error: "Forbidden",
      message: "You are not authorized to access this resource."
    }, status: :forbidden
  end

  def render_validation_errors(record)
    render json: { errors: record.errors.full_messages }, status: :unprocessable_content
  end

  def render_not_found(exception)
    @exception = exception
    render json: {
      error: "Not Found",
      message: @exception.message
    }, status: :not_found and return
  end
end
