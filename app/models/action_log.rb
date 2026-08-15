class ActionLog < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  validates :action, presence: true
  validates :resource_type, :resource_id, presence: true
end
