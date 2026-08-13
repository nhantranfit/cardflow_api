require "rails_helper"

RSpec.describe ProductPolicy, type: :policy do
  let(:product) { Product.new(name: "Gift Card", price: 100, status: :active) }
  let(:admin) { User.new(email: "ops.admin@cardflow.com", password: "password123", role: :admin) }
  let(:client) do
    User.new(email: "lan.nguyen@retailhub.vn", password: "password123", role: :client, payout_rate: 0.8)
  end

  describe "#index?" do
    it "allows admin" do
      expect(described_class.new(admin, product).index?).to be(true)
    end

    it "allows client" do
      expect(described_class.new(client, product).index?).to be(true)
    end
  end

  %i[create? update? destroy?].each do |action|
    describe "##{action}" do
      it "allows admin" do
        expect(described_class.new(admin, product).public_send(action)).to be(true)
      end

      it "denies client" do
        expect(described_class.new(client, product).public_send(action)).to be(false)
      end
    end
  end
end
