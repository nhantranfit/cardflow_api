require "rails_helper"

RSpec.describe IssueCard do
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

  def issue!(product_id: product.id, user: client)
    described_class.new(client: user, product_id: product_id).call
  end

  before do
    ClientProduct.create!(client: client, product: product)
  end

  describe "#call" do
    it "creates a card for an accessible active product" do
      expect { issue! }.to change(Card, :count).by(1)

      card = Card.last
      expect(card.client).to eq(client)
      expect(card.product).to eq(product)
      expect(card.status).to eq("issued")
      expect(card.activation_number).to be_present
      expect(card.pin).to be_present
      expect(card.cancelled_at).to be_nil
      expect(card.purchase_amount).to eq(80)
    end

    it "calculates and snapshots purchase_amount" do
      card = issue!

      expect(card.purchase_amount).to eq(80)

      product.update!(price: 200)
      client.update!(payout_rate: 0.5)

      expect(card.reload.purchase_amount).to eq(80)
    end

    it "generates a unique activation_number" do
      first = issue!
      second_product = Product.create!(brand: brand, name: "Gift Card 50", price: 50, status: :active)
      ClientProduct.create!(client: client, product: second_product)
      second = issue!(product_id: second_product.id)

      expect(first.activation_number).not_to eq(second.activation_number)
    end

    it "rejects when client has no access to the product" do
      other_product = Product.create!(brand: brand, name: "Other Card", price: 50, status: :active)

      expect {
        expect { issue!(product_id: other_product.id) }.to raise_error(
          IssueCard::Forbidden,
          "You do not have access to this product"
        )
      }.not_to change(Card, :count)
    end

    it "rejects when product is inactive" do
      product.update!(status: :inactive)

      expect {
        expect { issue! }.to raise_error(IssueCard::Unprocessable, "Product is not active")
      }.not_to change(Card, :count)
    end

    it "raises when product does not exist" do
      expect {
        expect { issue!(product_id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
      }.not_to change(Card, :count)
    end
  end
end
