class CardPolicy < ApplicationPolicy
  def index?
    user.client?
  end

  def create?
    user.client?
  end

  def cancel?
    user.client? && record.client_id == user.id
  end
end
