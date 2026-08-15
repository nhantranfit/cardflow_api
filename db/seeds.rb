# Idempotent seed data for local/manual API testing (including Issue Card).
# Load with: bin/rails db:seed

admin = User.find_or_initialize_by(email: "admin@example.com")
admin.assign_attributes(
  password: "password123",
  password_confirmation: "password123",
  role: "admin",
  payout_rate: nil
)
admin.save!

clients_data = [
  { email: "client1@example.com", payout_rate: 0.8 },
  { email: "client2@example.com", payout_rate: 0.75 },
  { email: "client3@example.com", payout_rate: 0.9 }
]

clients = clients_data.map do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(
    password: "password123",
    password_confirmation: "password123",
    role: "client",
    payout_rate: attrs[:payout_rate]
  )
  user.save!
  user
end

client1, client2, client3 = clients

brands_data = [
  { name: "ADIDAS", description: "Adidas - German sportswear powerhouse", status: "active" },
  { name: "PUMA", description: "Puma - Performance and lifestyle", status: "active" },
  { name: "REEBOK", description: "Reebok - Fitness focused brand", status: "active" },
  { name: "NIKE", description: "Nike - Just Do It", status: "active" },
  { name: "UNDER ARMOUR", description: "Under Armour - Performance apparel", status: "active" },
  { name: "LEGACY BRAND", description: "Inactive brand for negative tests", status: "inactive" }
]

brands = brands_data.each_with_object({}) do |attrs, memo|
  brand = Brand.find_or_initialize_by(name: attrs[:name])
  brand.assign_attributes(description: attrs[:description], status: attrs[:status])
  brand.save!
  memo[attrs[:name]] = brand
end

products_data = [
  { brand: "ADIDAS", name: "Adidas Gift Card 50", price: 50, status: "active" },
  { brand: "ADIDAS", name: "Adidas Gift Card 100", price: 100, status: "active" },
  { brand: "ADIDAS", name: "Adidas Gift Card 200", price: 200, status: "active" },
  { brand: "ADIDAS", name: "Adidas Inactive Card", price: 75, status: "inactive" },
  { brand: "PUMA", name: "Puma Gift Card 50", price: 50, status: "active" },
  { brand: "PUMA", name: "Puma Gift Card 100", price: 100, status: "active" },
  { brand: "PUMA", name: "Puma Gift Card 150", price: 150, status: "active" },
  { brand: "REEBOK", name: "Reebok Gift Card 80", price: 80, status: "active" },
  { brand: "REEBOK", name: "Reebok Gift Card 120", price: 120, status: "active" },
  { brand: "NIKE", name: "Nike Gift Card 100", price: 100, status: "active" },
  { brand: "NIKE", name: "Nike Gift Card 250", price: 250, status: "active" },
  { brand: "NIKE", name: "Nike Inactive Card", price: 90, status: "inactive" },
  { brand: "UNDER ARMOUR", name: "UA Gift Card 60", price: 60, status: "active" },
  { brand: "UNDER ARMOUR", name: "UA Gift Card 180", price: 180, status: "active" },
  { brand: "LEGACY BRAND", name: "Legacy Gift Card 40", price: 40, status: "inactive" }
]

products = products_data.each_with_object({}) do |attrs, memo|
  brand = brands.fetch(attrs[:brand])
  product = Product.find_or_initialize_by(brand: brand, name: attrs[:name])
  product.assign_attributes(price: attrs[:price], status: attrs[:status])
  product.save!
  memo[attrs[:name]] = product
end

# Client product access for Issue Card testing:
# - client1: broad Adidas/Puma access (includes one inactive product for reject cases)
# - client2: Nike/Reebok access
# - client3: Under Armour + shared Adidas 100
access_map = {
  client1 => [
    "Adidas Gift Card 50",
    "Adidas Gift Card 100",
    "Adidas Gift Card 200",
    "Adidas Inactive Card",
    "Puma Gift Card 50",
    "Puma Gift Card 100",
    "Puma Gift Card 150"
  ],
  client2 => [
    "Reebok Gift Card 80",
    "Reebok Gift Card 120",
    "Nike Gift Card 100",
    "Nike Gift Card 250",
    "Nike Inactive Card"
  ],
  client3 => [
    "UA Gift Card 60",
    "UA Gift Card 180",
    "Adidas Gift Card 100",
    "Legacy Gift Card 40"
  ]
}

access_map.each do |client, product_names|
  product_names.each do |name|
    ClientProduct.find_or_create_by!(client: client, product: products.fetch(name))
  end
end

puts "Seeded:"
puts "  admin:   admin@example.com / password123"
puts "  clients: client1..3@example.com / password123 (payout 0.8 / 0.75 / 0.9)"
puts "  brands:  #{Brand.count}"
puts "  products: #{Product.count} (active=#{Product.active.count}, inactive=#{Product.inactive.count})"
puts "  client_products: #{ClientProduct.count}"
puts "Example Issue Card amounts:"
puts "  client1 + Adidas Gift Card 100 => #{(100 * client1.payout_rate).round(2)}"
puts "  client2 + Nike Gift Card 250   => #{(250 * client2.payout_rate).round(2)}"
puts "  client3 + UA Gift Card 60      => #{(60 * client3.payout_rate).round(2)}"
