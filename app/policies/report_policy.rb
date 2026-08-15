class ReportPolicy < ApplicationPolicy
  def index?
    user.client? || user.admin?
  end
end
