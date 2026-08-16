require "rails_helper"

RSpec.describe "Api::V1::Clients", type: :request do
  let(:admin) { create_user(email: "ops.admin@cardflow.com", role: :admin) }
  let(:client_user) { create_user(email: "lan.nguyen@retailhub.vn", role: :client) }

  describe "GET /api/v1/clients" do
    before do
      create_user(email: "minh.tran@shopmart.vn", role: :client)
      create_user(email: "support.admin@cardflow.com", role: :admin)
    end

    it "returns only clients for admin" do
      get "/api/v1/clients", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      emails = json_body["clients"].map { |c| c["email"] }
      expect(emails).to include("minh.tran@shopmart.vn")
      expect(emails).not_to include("ops.admin@cardflow.com", "support.admin@cardflow.com")
      expect(json_body["clients"].first).to include("id", "email", "role", "payout_rate")
    end

    it "forbids client" do
      get "/api/v1/clients", headers: auth_headers(client_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/clients"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/clients" do
    let(:params) do
      {
        client: {
          email: "hoa.pham@vinmart.vn",
          password: "password123",
          payout_rate: 0.8,
          role: "admin"
        }
      }
    end

    it "creates a client for admin and ignores role param" do
      expect {
        post "/api/v1/clients", params: params, headers: auth_headers(admin), as: :json
      }.to change(User.client, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["client"]).to include(
        "email" => "hoa.pham@vinmart.vn",
        "role" => "client",
        "payout_rate" => "0.8"
      )
    end

    it "returns validation errors" do
      post "/api/v1/clients",
           params: { client: { email: "not-an-email", password: "password123", payout_rate: 0 } },
           headers: auth_headers(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["error"]).to eq("Unprocessable Entity")
      expect(json_body["message"]).to be_present
    end

    it "forbids client" do
      post "/api/v1/clients", params: params, headers: auth_headers(client_user), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/clients/:id" do
    let!(:target) { create_user(email: "duc.le@coopmart.vn", role: :client, payout_rate: 0.7) }

    it "updates a client for admin" do
      patch "/api/v1/clients/#{target.id}",
            params: { client: { payout_rate: 0.9 } },
            headers: auth_headers(admin),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["client"]["payout_rate"]).to eq("0.9")
      expect(target.reload.payout_rate).to eq(0.9)
    end

    it "does not update an admin through clients API" do
      patch "/api/v1/clients/#{admin.id}",
            params: { client: { email: "attacker@malicious.com" } },
            headers: auth_headers(admin),
            as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "forbids client" do
      patch "/api/v1/clients/#{target.id}",
            params: { client: { payout_rate: 0.5 } },
            headers: auth_headers(client_user),
            as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/clients/:id" do
    let!(:target) { create_user(email: "an.vo@lottemart.vn", role: :client) }

    it "destroys a client for admin" do
      expect {
        delete "/api/v1/clients/#{target.id}", headers: auth_headers(admin)
      }.to change(User.client, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Client deleted successfully")
    end

    it "forbids client" do
      delete "/api/v1/clients/#{target.id}", headers: auth_headers(client_user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
