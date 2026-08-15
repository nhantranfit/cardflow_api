require "rails_helper"

RSpec.describe ActionLogService do
  let(:user) do
    User.create!(email: "ops.admin@cardflow.com", password: "password123", role: :admin)
  end
  let(:brand) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }

  it "creates an action log for the user and resource" do
    expect {
      described_class.new(user, "create", brand).call
    }.to change(ActionLog, :count).by(1)

    log = ActionLog.last
    expect(log.user).to eq(user)
    expect(log.action).to eq("create")
    expect(log.resource_type).to eq("Brand")
    expect(log.resource_id).to eq(brand.id)
  end
end
