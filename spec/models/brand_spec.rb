require "rails_helper"

RSpec.describe Brand, type: :model do
  def build_brand(attrs = {})
    Brand.new({
      name: "Nike",
      description: "Gift cards",
      status: :active
    }.merge(attrs))
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build_brand).to be_valid
    end

    it "requires name" do
      brand = build_brand(name: nil)
      expect(brand).not_to be_valid
      expect(brand.errors[:name]).to be_present
    end

    it "enforces unique name" do
      build_brand.save!
      duplicate = build_brand(name: "Nike")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "rejects an invalid status" do
      brand = build_brand
      brand.status = 99
      expect(brand).not_to be_valid
      expect(brand.errors[:status]).to be_present
    end
  end

  describe "status enum" do
    it "exposes active? and inactive? predicates" do
      expect(build_brand(status: :active)).to be_active
      expect(build_brand(status: :inactive)).to be_inactive
    end

    it "defaults to active" do
      expect(Brand.new.status).to eq("active")
    end
  end
end
