require "rails_helper"

RSpec.describe ProductCatalogQuery do
  def create_client(email:)
    User.create!(
      email: email,
      password: "password123",
      role: :client,
      payout_rate: 0.8
    )
  end

  def create_brand(name:)
    Brand.create!(name: name, description: "#{name} description", status: :active)
  end

  def create_product(brand:, name:, status: :active)
    Product.create!(brand: brand, name: name, price: 100, status: status)
  end

  def assign_product(client:, product:)
    ClientProduct.create!(client: client, product: product)
  end

  def call_query(user:, params: {})
    described_class.new(user: user, params: params).call
  end

  let(:client) { create_client(email: "lan.nguyen@retailhub.vn") }
  let!(:adidas) { create_brand(name: "Adidas") }
  let!(:puma) { create_brand(name: "Puma") }

  let!(:adidas_card) { create_product(brand: adidas, name: "Adidas Gift Card") }
  let!(:adidas_voucher) { create_product(brand: adidas, name: "Adidas Voucher") }
  let!(:puma_card) { create_product(brand: puma, name: "Puma Gift Card") }
  let!(:inactive_card) { create_product(brand: adidas, name: "Adidas Inactive", status: :inactive) }
  let!(:unassigned_card) { create_product(brand: adidas, name: "Unassigned Card") }

  before do
    assign_product(client: client, product: adidas_card)
    assign_product(client: client, product: adidas_voucher)
    assign_product(client: client, product: puma_card)
    assign_product(client: client, product: inactive_card)
  end

  describe "#call" do
    it "returns only assigned active products ordered by name" do
      result = call_query(user: client)

      expect(result.map(&:name)).to eq([
        "Adidas Gift Card",
        "Adidas Voucher",
        "Puma Gift Card"
      ])
    end

    it "excludes unassigned and inactive products" do
      result = call_query(user: client)

      expect(result).not_to include(inactive_card, unassigned_card)
    end

    it "returns an empty relation when client has no accessible products" do
      other_client = create_client(email: "minh.tran@shopmart.vn")

      expect(call_query(user: other_client)).to be_empty
    end

    context "when filtering by brand_id" do
      it "returns assigned active products for that brand" do
        result = call_query(user: client, params: { brand_id: adidas.id })

        expect(result.map(&:name)).to contain_exactly("Adidas Gift Card", "Adidas Voucher")
      end

      it "ignores blank brand_id" do
        result = call_query(user: client, params: { brand_id: "" })

        expect(result.map(&:name)).to contain_exactly(
          "Adidas Gift Card",
          "Adidas Voucher",
          "Puma Gift Card"
        )
      end
    end

    context "when searching by name" do
      it "filters products with case-insensitive partial match" do
        result = call_query(user: client, params: { search: "gift" })

        expect(result.map(&:name)).to contain_exactly("Adidas Gift Card", "Puma Gift Card")
      end

      it "escapes LIKE wildcards in the search term" do
        wildcard_product = create_product(brand: adidas, name: "100% Bonus Card")
        assign_product(client: client, product: wildcard_product)

        result = call_query(user: client, params: { search: "100%" })

        expect(result.map(&:name)).to contain_exactly("100% Bonus Card")
      end

      it "ignores blank search" do
        result = call_query(user: client, params: { search: "" })

        expect(result.map(&:name)).to contain_exactly(
          "Adidas Gift Card",
          "Adidas Voucher",
          "Puma Gift Card"
        )
      end
    end

    context "when filtering by status" do
      it "keeps active products when status is active" do
        result = call_query(user: client, params: { status: "active" })

        expect(result.map(&:name)).to contain_exactly(
          "Adidas Gift Card",
          "Adidas Voucher",
          "Puma Gift Card"
        )
      end

      it "returns no products when status is inactive" do
        # Base scope already limits to active products.
        result = call_query(user: client, params: { status: "inactive" })

        expect(result).to be_empty
      end
    end

    context "when combining filters" do
      it "applies brand_id and search together" do
        result = call_query(
          user: client,
          params: { brand_id: adidas.id, search: "Gift" }
        )

        expect(result.map(&:name)).to contain_exactly("Adidas Gift Card")
      end
    end
  end
end
