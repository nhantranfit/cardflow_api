require "rails_helper"

RSpec.describe Product, type: :model do
  let(:brand) { Brand.create!(name: "Nike", description: "", status: :active) }

  def build_product(attrs = {})
    Product.new({
      brand: brand,
      name: "Nike Air Force 1",
      price: 100,
      status: :active
    }.merge(attrs))
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build_product).to be_valid
    end

    it "requires a brand" do
      product = build_product(brand: nil)
      expect(product).not_to be_valid
      expect(product.errors[:brand]).to be_present
    end

    it "requires name" do
      product = build_product(name: nil)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to be_present
    end

    it "requires price greater than 0" do
      expect(build_product(price: nil)).not_to be_valid
      expect(build_product(price: 0)).not_to be_valid
      expect(build_product(price: -1)).not_to be_valid
    end

    it "rejects an invalid status" do
      product = build_product
      product.status = 99
      expect(product).not_to be_valid
      expect(product.errors[:status]).to be_present
    end
  end

  describe "status enum" do
    it "exposes active? and inactive? predicates" do
      expect(build_product(status: :active)).to be_active
      expect(build_product(status: :inactive)).to be_inactive
    end

    it "defaults to active" do
      expect(Product.new.status).to eq("active")
    end
  end

  describe "associations" do
    it "belongs to brand" do
      product = build_product
      product.save!
      expect(product.brand).to eq(brand)
    end
  end
end
