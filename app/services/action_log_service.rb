class ActionLogService
  def initialize(user, action, resource)
    @user = user
    @action = action
    @resource = resource
  end

  def call
    ActionLog.create!(
      user: @user,
      action: @action,
      resource_type: @resource.class.base_class.name,
      resource_id: @resource.id
    )
  end
end
