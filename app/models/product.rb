class Product < ApplicationRecord
  belongs_to :brand
  has_many :cards, dependent: :restrict_with_error

  enum :status, { active: 0, inactive: 1 }, validate: true

  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
