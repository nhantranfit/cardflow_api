require "rails_helper"

RSpec.describe ClientOperationsReportQuery do
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
  let(:other_client) do
    User.create!(
      email: "minh.tran@shopmart.vn",
      password: "password123",
      role: :client,
      payout_rate: 0.75
    )
  end

  def issue!(user: client)
    ClientProduct.find_or_create_by!(client: user, product: product)
    IssueCard.new(client: user, product_id: product.id).call
  end

  def call_query(params: {})
    described_class.new(client: client, params: params).call
  end

  describe "#call" do
    it "returns all of the client's cards when status is omitted" do
      issued = issue!
      cancelled = issue!
      cancelled.update!(status: :cancelled, cancelled_at: Time.current)
      issue!(user: other_client)

      expect(call_query).to contain_exactly(issued, cancelled)
    end

    it "returns only issued cards for status=spending" do
      issued = issue!
      cancelled = issue!
      cancelled.update!(status: :cancelled, cancelled_at: Time.current)

      expect(call_query(params: { status: "spending" })).to contain_exactly(issued)
    end

    it "returns only cancelled cards for status=cancellations" do
      issue!
      cancelled = issue!
      cancelled.update!(status: :cancelled, cancelled_at: Time.current)

      expect(call_query(params: { status: "cancellations" })).to contain_exactly(cancelled)
    end

    it "orders cards by created_at descending" do
      older = issue!
      older.update_columns(created_at: 2.days.ago)
      newer = issue!
      newer.update_columns(created_at: 1.day.ago)

      expect(call_query.map(&:id)).to eq([ newer.id, older.id ])
    end
  end
end
