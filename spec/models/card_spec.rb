require "rails_helper"

RSpec.describe Card, type: :model do
  let(:brand) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }
  let(:product) { Product.create!(brand: brand, name: "Gift Card 100", price: 100, status: :active) }
  let(:client) do
    User.create!(
      email: "lan.nguyen@retailhub.vn",
      password: "password123",
      role: :client,
      payout_rate: 0.8
    )
  end
  let(:admin) do
    User.create!(
      email: "ops.admin@cardflow.com",
      password: "password123",
      role: :admin
    )
  end

  def build_card(attrs = {})
    Card.new({
      client: client,
      product: product,
      activation_number: "ACT-#{SecureRandom.hex(4)}",
      purchase_amount: 80,
      status: :issued
    }.merge(attrs))
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build_card).to be_valid
    end

    it "requires a client" do
      card = build_card(client: nil)
      expect(card).not_to be_valid
      expect(card.errors[:client]).to be_present
    end

    it "requires a product" do
      card = build_card(product: nil)
      expect(card).not_to be_valid
      expect(card.errors[:product]).to be_present
    end

    it "requires activation_number" do
      card = build_card(activation_number: nil)
      expect(card).not_to be_valid
      expect(card.errors[:activation_number]).to be_present
    end

    it "enforces unique activation_number" do
      build_card(activation_number: "ACT-UNIQUE").save!
      duplicate = build_card(activation_number: "ACT-UNIQUE")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:activation_number]).to include("has already been taken")
    end

    it "requires purchase_amount greater than 0" do
      expect(build_card(purchase_amount: nil)).not_to be_valid
      expect(build_card(purchase_amount: 0)).not_to be_valid
      expect(build_card(purchase_amount: -1)).not_to be_valid
    end

    it "rejects an invalid status" do
      card = build_card
      card.status = 99
      expect(card).not_to be_valid
      expect(card.errors[:status]).to be_present
    end

    it "requires client to have client role" do
      card = build_card(client: admin)
      expect(card).not_to be_valid
      expect(card.errors[:client]).to include("must be a client")
    end

    it "allows optional pin" do
      expect(build_card(pin: nil)).to be_valid
      expect(build_card(pin: "1234")).to be_valid
    end
  end

  describe "status enum" do
    it "exposes issued? and cancelled? predicates" do
      expect(build_card(status: :issued)).to be_issued
      expect(build_card(status: :cancelled)).to be_cancelled
    end

    it "defaults to issued" do
      expect(Card.new.status).to eq("issued")
    end
  end

  describe "associations" do
    it "belongs to client and product" do
      card = build_card
      card.save!

      expect(card.client).to eq(client)
      expect(card.product).to eq(product)
      expect(client.cards).to include(card)
      expect(product.cards).to include(card)
    end
  end
end
