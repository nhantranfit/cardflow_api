require "rails_helper"

RSpec.describe ReportPolicy, type: :policy do
  let(:admin) { User.new(email: "ops.admin@cardflow.com", password: "password123", role: :admin) }
  let(:client) do
    User.new(email: "lan.nguyen@retailhub.vn", password: "password123", role: :client, payout_rate: 0.8)
  end

  describe "#index?" do
    it "allows client" do
      expect(described_class.new(client, :report).index?).to be(true)
    end

    it "allows admin" do
      expect(described_class.new(admin, :report).index?).to be(true)
    end
  end
end
