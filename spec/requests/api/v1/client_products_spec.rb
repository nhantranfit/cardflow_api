require "rails_helper"

RSpec.describe "Api::V1::ClientProducts", type: :request do
  let(:admin) { create_user(email: "ops.admin@cardflow.com", role: :admin) }
  let(:client_user) { create_user(email: "lan.nguyen@retailhub.vn", role: :client) }
  let(:other_client) { create_user(email: "minh.tran@shopmart.vn", role: :client) }
  let!(:brand) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }
  let!(:product) do
    Product.create!(brand: brand, name: "Gift Card 100", price: 100, status: :active)
  end
  let!(:inactive_product) do
    Product.create!(brand: brand, name: "Gift Card 50", price: 50, status: :inactive)
  end

  describe "POST /api/v1/clients/:client_id/products" do
    it "assigns a product to a client for admin" do
      expect {
        post "/api/v1/clients/#{client_user.id}/products",
             params: { product_id: product.id },
             headers: auth_headers(admin),
             as: :json
      }.to change(ClientProduct, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["client_product"]).to include(
        "client_id" => client_user.id,
        "product_id" => product.id
      )
    end

    it "allows assigning an inactive product" do
      post "/api/v1/clients/#{client_user.id}/products",
           params: { product_id: inactive_product.id },
           headers: auth_headers(admin),
           as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["client_product"]["product_id"]).to eq(inactive_product.id)
    end

    it "returns not found when client does not exist" do
      post "/api/v1/clients/0/products",
           params: { product_id: product.id },
           headers: auth_headers(admin),
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when client_id points to an admin" do
      post "/api/v1/clients/#{admin.id}/products",
           params: { product_id: product.id },
           headers: auth_headers(admin),
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when product does not exist" do
      post "/api/v1/clients/#{client_user.id}/products",
           params: { product_id: 0 },
           headers: auth_headers(admin),
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns validation error for duplicate assignment" do
      ClientProduct.create!(client: client_user, product: product)

      expect {
        post "/api/v1/clients/#{client_user.id}/products",
             params: { product_id: product.id },
             headers: auth_headers(admin),
             as: :json
      }.not_to change(ClientProduct, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["error"]).to eq("Unprocessable Entity")
      expect(json_body["message"]).to be_present
    end

    it "forbids client" do
      post "/api/v1/clients/#{other_client.id}/products",
           params: { product_id: product.id },
           headers: auth_headers(client_user),
           as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/v1/clients/#{client_user.id}/products",
           params: { product_id: product.id },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/clients/:client_id/products/:product_id" do
    let!(:assignment) { ClientProduct.create!(client: client_user, product: product) }

    it "revokes a product from a client for admin" do
      expect {
        delete "/api/v1/clients/#{client_user.id}/products/#{product.id}",
               headers: auth_headers(admin)
      }.to change(ClientProduct, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Product deleted successfully")
    end

    it "returns not found when assignment does not exist" do
      delete "/api/v1/clients/#{client_user.id}/products/#{inactive_product.id}",
             headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "forbids client" do
      delete "/api/v1/clients/#{client_user.id}/products/#{product.id}",
             headers: auth_headers(client_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      delete "/api/v1/clients/#{client_user.id}/products/#{product.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
