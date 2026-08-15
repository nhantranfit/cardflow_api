class Card < ApplicationRecord
  belongs_to :client, class_name: "User"
  belongs_to :product

  enum :status, { issued: 0, cancelled: 1 }, validate: true

  validates :activation_number, presence: true, uniqueness: true
  validates :purchase_amount, presence: true, numericality: { greater_than: 0 }
  validate :client_must_be_client_role

  private

  def client_must_be_client_role
    errors.add(:client, "must be a client") unless client&.client?
  end
end
