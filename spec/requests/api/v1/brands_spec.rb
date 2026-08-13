require "rails_helper"

RSpec.describe "Api::V1::Brands", type: :request do
  let(:admin) { create_user(email: "admin@example.com", role: :admin) }
  let(:client) { create_user(email: "client@example.com", role: :client) }

  def create_brand(attrs = {})
    Brand.create!({
      name: "Nike",
      description: "Gift cards",
      status: :active
    }.merge(attrs))
  end

  describe "GET /api/v1/brands" do
    before { create_brand }

    it "returns brands for admin" do
      get "/api/v1/brands", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["brands"].size).to eq(1)
      expect(json_body["brands"].first).to include(
        "name" => "Nike",
        "description" => "Gift cards",
        "status" => "active"
      )
    end

    it "forbids client" do
      get "/api/v1/brands", headers: auth_headers(client)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/brands"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/brands" do
    let(:params) do
      { brand: { name: "Adidas", description: "Sports cards", status: "active" } }
    end

    it "creates a brand for admin" do
      expect {
        post "/api/v1/brands", params: params, headers: auth_headers(admin), as: :json
      }.to change(Brand, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["brand"]).to include(
        "name" => "Adidas",
        "description" => "Sports cards",
        "status" => "active"
      )
    end

    it "returns validation errors" do
      post "/api/v1/brands",
           params: { brand: { name: "", description: "x" } },
           headers: auth_headers(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["errors"]).to include("Name can't be blank")
    end

    it "forbids client" do
      post "/api/v1/brands", params: params, headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/brands/:id" do
    let!(:brand) { create_brand }

    it "updates a brand for admin" do
      patch "/api/v1/brands/#{brand.id}",
            params: { brand: { status: "inactive" } },
            headers: auth_headers(admin),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["brand"]["status"]).to eq("inactive")
      expect(brand.reload).to be_inactive
    end

    it "forbids client" do
      patch "/api/v1/brands/#{brand.id}",
            params: { brand: { name: "Other" } },
            headers: auth_headers(client),
            as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/brands/:id" do
    let!(:brand) { create_brand }

    it "destroys a brand for admin" do
      expect {
        delete "/api/v1/brands/#{brand.id}", headers: auth_headers(admin)
      }.to change(Brand, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Brand deleted successfully")
    end

    it "forbids client" do
      delete "/api/v1/brands/#{brand.id}", headers: auth_headers(client)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
