class ProductPolicy < ApplicationPolicy
  def index?
    user.admin? || user.client?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
