require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/login" do
    let!(:user) { create_user(email: "admin@example.com", role: :admin) }

    it "returns a token for valid credentials" do
      post "/api/v1/auth/login", params: { email: user.email, password: "password123" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["token"]).to be_present
      expect(json_body["user"]).to eq(
        "id" => user.id,
        "email" => user.email,
        "role" => "admin"
      )
    end

    it "returns unauthorized for invalid password" do
      post "/api/v1/auth/login", params: { email: user.email, password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_body).to eq(
        "error" => "Unauthorized",
        "message" => "Invalid email or password"
      )
    end

    it "returns unauthorized for unknown email" do
      post "/api/v1/auth/login", params: { email: "missing@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_body).to eq(
        "error" => "Unauthorized",
        "message" => "Email not found"
      )
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { create_user(email: "nhantran@example.com", role: :client) }

    it "returns the current user for a valid token" do
      get "/api/v1/auth/me", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_body["user"]).to eq(
        "id" => user.id,
        "email" => user.email,
        "role" => "client"
      )
    end

    it "returns unauthorized when the token is missing" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body).to eq(
        "error" => "Unauthorized",
        "message" => "Missing token"
      )
    end

    it "returns unauthorized for an invalid token" do
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer invalid.token" }

      expect(response).to have_http_status(:unauthorized)
      expect(json_body).to eq(
        "error" => "Unauthorized",
        "message" => "Invalid or expired token"
      )
    end

    it "returns unauthorized for an expired token" do
      get "/api/v1/auth/me", headers: auth_headers(user, exp: 1.hour.ago)

      expect(response).to have_http_status(:unauthorized)
      expect(json_body).to eq(
        "error" => "Unauthorized",
        "message" => "Invalid or expired token"
      )
    end
  end
end
