require "rails_helper"

RSpec.describe AdminOperationsReportQuery do
  let(:adidas) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }
  let(:nike) { Brand.create!(name: "Nike", description: "Just Do It", status: :active) }
  let(:adidas_product) { Product.create!(brand: adidas, name: "Adidas Gift Card 100", price: 100, status: :active) }
  let(:nike_product) { Product.create!(brand: nike, name: "Nike Gift Card 100", price: 100, status: :active) }
  let(:client) do
    User.create!(email: "lan.nguyen@retailhub.vn", password: "password123", role: :client, payout_rate: 0.8)
  end
  let(:other_client) do
    User.create!(email: "minh.tran@shopmart.vn", password: "password123", role: :client, payout_rate: 0.75)
  end

  def issue!(user:, product:)
    ClientProduct.find_or_create_by!(client: user, product: product)
    IssueCard.new(client: user, product_id: product.id).call
  end

  def call_query(params: {})
    described_class.new(params: params).call
  end

  describe "#call" do
    it "returns all cards when no filters are provided" do
      first = issue!(user: client, product: adidas_product)
      second = issue!(user: other_client, product: nike_product)

      expect(call_query).to contain_exactly(first, second)
    end

    it "filters by brand_id" do
      adidas_card = issue!(user: client, product: adidas_product)
      issue!(user: other_client, product: nike_product)

      expect(call_query(params: { brand_id: adidas.id })).to contain_exactly(adidas_card)
    end

    it "filters by client_id" do
      client_card = issue!(user: client, product: adidas_product)
      issue!(user: other_client, product: nike_product)

      expect(call_query(params: { client_id: client.id })).to contain_exactly(client_card)
    end

    it "filters by brand_id and client_id together" do
      matching = issue!(user: client, product: adidas_product)
      issue!(user: client, product: nike_product)
      issue!(user: other_client, product: adidas_product)

      expect(
        call_query(params: { brand_id: adidas.id, client_id: client.id })
      ).to contain_exactly(matching)
    end

    it "filters by status=spending" do
      issued = issue!(user: client, product: adidas_product)
      cancelled = issue!(user: client, product: nike_product)
      cancelled.update!(status: :cancelled, cancelled_at: Time.current)

      expect(call_query(params: { status: "spending" })).to contain_exactly(issued)
    end

    it "filters by status=cancellations" do
      issue!(user: client, product: adidas_product)
      cancelled = issue!(user: client, product: nike_product)
      cancelled.update!(status: :cancelled, cancelled_at: Time.current)

      expect(call_query(params: { status: "cancellations" })).to contain_exactly(cancelled)
    end

    it "raises when brand_id does not exist" do
      expect {
        call_query(params: { brand_id: 0 })
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises when client_id does not exist" do
      expect {
        call_query(params: { client_id: 0 })
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
