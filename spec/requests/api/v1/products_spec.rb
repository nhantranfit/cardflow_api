require "rails_helper"

RSpec.describe "Api::V1::Products", type: :request do
  let(:admin) { create_user(email: "admin@example.com", role: :admin) }
  let(:client) { create_user(email: "client@example.com", role: :client) }
  let!(:brand) { Brand.create!(name: "Acme", description: "Cards", status: :active) }

  def create_product(attrs = {})
    Product.create!({
      brand: brand,
      name: "Gift Card 100",
      price: 100,
      status: :active
    }.merge(attrs))
  end

  describe "GET /api/v1/products" do
    before { create_product }

    it "returns products for admin" do
      get "/api/v1/products", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["products"].size).to eq(1)
      expect(json_body["products"].first).to include(
        "brand_name" => brand.name,
        "name" => "Gift Card 100",
        "price" => "100.0",
        "status" => "active"
      )
    end

    it "forbids client" do
      get "/api/v1/products", headers: auth_headers(client)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/products"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/products" do
    let(:params) do
      {
        product: {
          brand_id: brand.id,
          name: "Gift Card 50",
          price: 50,
          status: "active"
        }
      }
    end

    it "creates a product for admin" do
      expect {
        post "/api/v1/products", params: params, headers: auth_headers(admin), as: :json
      }.to change(Product, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["product"]).to include(
        "brand_name" => brand.name,
        "name" => "Gift Card 50",
        "status" => "active"
      )
    end

    it "returns validation errors" do
      post "/api/v1/products",
           params: { product: { brand_id: brand.id, name: "", price: 0 } },
           headers: auth_headers(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["errors"]).to be_present
    end

    it "forbids client" do
      post "/api/v1/products", params: params, headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/products/:id" do
    let!(:product) { create_product }

    it "updates a product for admin" do
      patch "/api/v1/products/#{product.id}",
            params: { product: { status: "inactive" } },
            headers: auth_headers(admin),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["product"]["status"]).to eq("inactive")
      expect(product.reload).to be_inactive
    end

    it "forbids client" do
      patch "/api/v1/products/#{product.id}",
            params: { product: { name: "Other" } },
            headers: auth_headers(client),
            as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/products/:id" do
    let!(:product) { create_product }

    it "destroys a product for admin" do
      expect {
        delete "/api/v1/products/#{product.id}", headers: auth_headers(admin)
      }.to change(Product, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Product deleted successfully")
    end

    it "forbids client" do
      delete "/api/v1/products/#{product.id}", headers: auth_headers(client)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
