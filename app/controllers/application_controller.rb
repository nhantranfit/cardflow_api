class ApplicationController < ActionController::API
  include Authenticatable
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def user_json(user)
    { id: user.id, email: user.email, role: user.role }
  end

  def render_error(error:, message:, status:)
    render json: { error: error, message: message }, status: status
  end

  def render_forbidden
    render_error(
      error: "Forbidden",
      message: "You are not authorized to access this resource.",
      status: :forbidden
    )
  end

  def render_validation_errors(record)
    render_error(
      error: "Unprocessable Entity",
      message: record.errors.full_messages.to_sentence,
      status: :unprocessable_content
    )
  end

  def render_not_found(exception)
    render_error(
      error: "Not Found",
      message: exception.message,
      status: :not_found
    )
  end

  def log_action(action, resource, user: current_user)
    ActionLogService.new(user, action, resource).call
  end
end
