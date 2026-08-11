class ApplicationController < ActionController::API
  include Authenticatable

  private

  def user_json(user)
    { id: user.id, email: user.email, role: user.role }
  end
end
