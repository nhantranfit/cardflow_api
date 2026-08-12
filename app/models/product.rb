class Product < ApplicationRecord
  belongs_to :brand

  enum :status, { active: 0, inactive: 1 }, validate: true

  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
