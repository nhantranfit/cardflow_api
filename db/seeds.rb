# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create admin/client users
admin = User.find_or_initialize_by(email: "admin@example.com")
admin.assign_attributes(
  password: "password123",
  password_confirmation: "password123",
  role: "admin",
  payout_rate: nil
)
admin.save!

clients = [
  { email: "client1@example.com", payout_rate: 0.8 },
  { email: "client2@example.com", payout_rate: 0.75 },
  { email: "client3@example.com", payout_rate: 0.9 }
]

clients.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(
    password: "password123",
    password_confirmation: "password123",
    role: "client",
    payout_rate: attrs[:payout_rate]
  )
  user.save!
end
