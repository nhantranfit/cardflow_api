require "rails_helper"

RSpec.describe User, type: :model do
  def build_admin(attrs = {})
    User.new({
      email: "admin@example.com",
      password: "password123",
      role: :admin
    }.merge(attrs))
  end

  def build_client(attrs = {})
    User.new({
      email: "nhantran@example.com",
      password: "password123",
      role: :client,
      payout_rate: 0.8
    }.merge(attrs))
  end

  describe "validations" do
    it "is valid as an admin without payout_rate" do
      expect(build_admin).to be_valid
    end

    it "is valid as a client with payout_rate" do
      expect(build_client).to be_valid
    end

    describe "email" do
      it "requires email" do
        user = build_admin(email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it "rejects invalid email format" do
        user = build_admin(email: "not-an-email")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("is invalid")
      end

      it "normalizes email by stripping and downcasing" do
        user = build_admin(email: "  Admin@Example.COM  ")
        user.valid?
        expect(user.email).to eq("admin@example.com")
      end

      it "enforces unique email" do
        build_admin.save!
        duplicate = build_client(email: "admin@example.com")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include("has already been taken")
      end
    end

    describe "password" do
      it "requires a password on create" do
        user = build_admin(password: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end

      it "authenticates with the correct password" do
        user = build_admin
        user.save!
        expect(user.authenticate("password123")).to eq(user)
      end

      it "does not authenticate with an incorrect password" do
        user = build_admin
        user.save!
        expect(user.authenticate("wrong")).to eq(false)
      end
    end

    describe "role" do
      it "requires a role" do
        user = build_admin(role: nil)
        expect(user).not_to be_valid
        expect(user.errors[:role]).to include("is not included in the list")
      end

      it "rejects an invalid role" do
        user = build_admin
        user.role = "superuser"
        expect(user).not_to be_valid
        expect(user.errors[:role]).to include("is not included in the list")
      end

      it "exposes admin? and client? predicates" do
        expect(build_admin).to be_admin
        expect(build_admin).not_to be_client
        expect(build_client).to be_client
        expect(build_client).not_to be_admin
      end
    end

    describe "payout_rate" do
      it "requires payout_rate for clients" do
        user = build_client(payout_rate: nil)
        expect(user).not_to be_valid
        expect(user.errors[:payout_rate]).to include("can't be blank")
      end

      it "rejects payout_rate for admins" do
        user = build_admin(payout_rate: 0.8)
        expect(user).not_to be_valid
        byebug
        expect(user.errors[:payout_rate]).to include("must be blank")
      end

      it "rejects payout_rate of zero for clients" do
        user = build_client(payout_rate: 0)
        expect(user).not_to be_valid
        expect(user.errors[:payout_rate]).to include("must be greater than 0")
      end

      it "rejects payout_rate greater than 1 for clients" do
        user = build_client(payout_rate: 1.1)
        expect(user).not_to be_valid
        expect(user.errors[:payout_rate]).to include("must be less than or equal to 1")
      end

      it "allows payout_rate of 1 for clients" do
        expect(build_client(payout_rate: 1)).to be_valid
      end
    end
  end
end
