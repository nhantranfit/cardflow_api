require "rails_helper"

RSpec.describe ClientProductPolicy, type: :policy do
  let(:record) { ClientProduct.new }
  let(:admin) { User.new(email: "ops.admin@cardflow.com", password: "password123", role: :admin) }
  let(:client) do
    User.new(email: "lan.nguyen@retailhub.vn", password: "password123", role: :client, payout_rate: 0.8)
  end

  %i[create? destroy?].each do |action|
    describe "##{action}" do
      it "allows admin" do
        expect(described_class.new(admin, record).public_send(action)).to be(true)
      end

      it "denies client" do
        expect(described_class.new(client, record).public_send(action)).to be(false)
      end
    end
  end
end
