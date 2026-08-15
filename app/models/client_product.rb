class ClientProduct < ApplicationRecord
  belongs_to :client, class_name: "User"
  belongs_to :product

  validates :client_id, uniqueness: { scope: :product_id, message: "already has access to this product" }
  validate :client_must_be_client_role

  private

  def client_must_be_client_role
    errors.add(:client, "must be a client") unless client&.client?
  end
end
