class User < ApplicationRecord
  has_secure_password

  has_many :client_products, foreign_key: :client_id, dependent: :destroy
  has_many :accessible_products, through: :client_products, source: :product
  has_many :cards, foreign_key: :client_id, dependent: :restrict_with_error

  enum :role, { admin: "admin", client: "client" }, validate: true

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :payout_rate, presence: true,
                          numericality: { greater_than: 0, less_than_or_equal_to: 1 },
                          if: :client?
  validates :payout_rate, absence: true, if: :admin?


end
