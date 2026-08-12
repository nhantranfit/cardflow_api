require "rails_helper"

RSpec.describe JsonWebToken do
  let(:payload) { { sub: 1, role: "admin" } }

  describe ".encode / .decode" do
    it "round-trips a payload" do
      token = described_class.encode(payload)
      decoded = described_class.decode(token)

      expect(decoded[:sub]).to eq(1)
      expect(decoded[:role]).to eq("admin")
      expect(decoded[:exp]).to be_present
    end

    it "returns nil for an invalid token" do
      expect(described_class.decode("not.a.jwt")).to be_nil
    end

    it "returns nil for an expired token" do
      token = described_class.encode(payload, exp: 1.hour.ago)
      expect(described_class.decode(token)).to be_nil
    end
  end
end
