require "rails_helper"

RSpec.describe CardPolicy, type: :policy do
  let(:card) { Card.new(client_id: client.id) }
  let(:admin) { User.new(id: 1, email: "ops.admin@cardflow.com", password: "password123", role: :admin) }
  let(:client) do
    User.new(id: 2, email: "lan.nguyen@retailhub.vn", password: "password123", role: :client, payout_rate: 0.8)
  end
  let(:other_client) do
    User.new(id: 3, email: "minh.tran@shopmart.vn", password: "password123", role: :client, payout_rate: 0.75)
  end

  describe "#index?" do
    it "allows client" do
      expect(described_class.new(client, Card).index?).to be(true)
    end

    it "denies admin" do
      expect(described_class.new(admin, Card).index?).to be(false)
    end
  end

  describe "#create?" do
    it "allows client" do
      expect(described_class.new(client, card).create?).to be(true)
    end

    it "denies admin" do
      expect(described_class.new(admin, card).create?).to be(false)
    end
  end

  describe "#cancel?" do
    it "allows the owning client" do
      expect(described_class.new(client, card).cancel?).to be(true)
    end

    it "denies another client" do
      expect(described_class.new(other_client, card).cancel?).to be(false)
    end

    it "denies admin" do
      expect(described_class.new(admin, card).cancel?).to be(false)
    end
  end
end
