require "rails_helper"

RSpec.describe "Action logging", type: :request do
  let(:admin) { create_user(email: "ops.admin@cardflow.com", role: :admin) }
  let(:client) { create_user(email: "lan.nguyen@retailhub.vn", role: :client, payout_rate: 0.8) }
  let!(:brand) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }
  let!(:product) { Product.create!(brand: brand, name: "Gift Card 100", price: 100, status: :active) }

  it "logs successful login" do
    expect {
      post "/api/v1/auth/login",
           params: { email: admin.email, password: "password123" },
           as: :json
    }.to change(ActionLog, :count).by(1)

    expect(ActionLog.last).to have_attributes(
      user_id: admin.id,
      action: "login",
      resource_type: "User",
      resource_id: admin.id
    )
  end

  it "logs brand create" do
    expect {
      post "/api/v1/brands",
           params: { brand: { name: "Puma", description: "Lifestyle", status: "active" } },
           headers: auth_headers(admin),
           as: :json
    }.to change(ActionLog, :count).by(1)

    expect(ActionLog.last.action).to eq("create")
    expect(ActionLog.last.resource_type).to eq("Brand")
  end

  it "logs card issue and cancel" do
    ClientProduct.create!(client: client, product: product)

    expect {
      post "/api/v1/cards",
           params: { card: { product_id: product.id } },
           headers: auth_headers(client),
           as: :json
    }.to change(ActionLog, :count).by(1)

    card = Card.last
    expect(ActionLog.last).to have_attributes(action: "create", resource_type: "Card", resource_id: card.id)

    expect {
      patch "/api/v1/cards/#{card.id}/cancel", headers: auth_headers(client), as: :json
    }.to change(ActionLog, :count).by(1)

    expect(ActionLog.last).to have_attributes(action: "cancel", resource_type: "Card", resource_id: card.id)
  end

  it "logs brand destroy after the brand is removed" do
    disposable = Brand.create!(name: "Temp Brand", description: "Temp", status: :active)

    expect {
      delete "/api/v1/brands/#{disposable.id}", headers: auth_headers(admin), as: :json
    }.to change(ActionLog, :count).by(1)

    expect(ActionLog.last).to have_attributes(
      action: "destroy",
      resource_type: "Brand",
      resource_id: disposable.id
    )
    expect(Brand.exists?(disposable.id)).to be(false)
  end
end
