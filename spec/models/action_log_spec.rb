require "rails_helper"

RSpec.describe ActionLog, type: :model do
  let(:user) do
    User.create!(email: "ops.admin@cardflow.com", password: "password123", role: :admin)
  end
  let(:brand) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }

  it "is valid with user, action, and resource" do
    log = described_class.new(user: user, action: "create", resource: brand)

    expect(log).to be_valid
  end

  it "requires action" do
    log = described_class.new(user: user, action: nil, resource: brand)

    expect(log).not_to be_valid
    expect(log.errors[:action]).to be_present
  end

  it "can reference a destroyed resource by type and id" do
    brand.destroy!
    log = described_class.create!(
      user: user,
      action: "destroy",
      resource_type: "Brand",
      resource_id: brand.id
    )

    expect(log.resource_type).to eq("Brand")
    expect(log.resource_id).to eq(brand.id)
  end
end
