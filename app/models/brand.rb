class Brand < ApplicationRecord
  has_many :products, dependent: :restrict_with_error
  
  enum :status, { active: 0, inactive: 1 }, validate: true

  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true, uniqueness: true
end
