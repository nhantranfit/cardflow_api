require "rails_helper"

RSpec.describe "Api::V1::Cards", type: :request do
  let(:admin) { create_user(email: "ops.admin@cardflow.com", role: :admin) }
  let(:client) { create_user(email: "lan.nguyen@retailhub.vn", role: :client, payout_rate: 0.8) }
  let(:other_client) { create_user(email: "minh.tran@shopmart.vn", role: :client, payout_rate: 0.75) }
  let!(:brand) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }
  let!(:product) { Product.create!(brand: brand, name: "Gift Card 100", price: 100, status: :active) }

  before do
    ClientProduct.create!(client: client, product: product)
  end

  describe "POST /api/v1/cards" do
    it "issues a card for the current client" do
      expect {
        post "/api/v1/cards",
             params: { card: { product_id: product.id } },
             headers: auth_headers(client),
             as: :json
      }.to change(Card, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["card"]).to include(
        "client_id" => client.id,
        "product_id" => product.id,
        "purchase_amount" => "80.0",
        "status" => "issued"
      )
      expect(json_body["card"]["activation_number"]).to be_present
      expect(Card.last.client_id).to eq(client.id)
    end

    it "ignores client-supplied purchase_amount, status, and client_id" do
      post "/api/v1/cards",
           params: {
             card: {
               product_id: product.id,
               purchase_amount: 1,
               status: "cancelled",
               client_id: other_client.id,
               activation_number: "CLIENT-FORCED"
             }
           },
           headers: auth_headers(client),
           as: :json

      expect(response).to have_http_status(:created)
      card = Card.last
      expect(card.purchase_amount).to eq(80)
      expect(card.status).to eq("issued")
      expect(card.client_id).to eq(client.id)
      expect(card.activation_number).not_to eq("CLIENT-FORCED")
    end

    it "snapshots purchase_amount at issue time" do
      post "/api/v1/cards",
           params: { card: { product_id: product.id } },
           headers: auth_headers(client),
           as: :json

      card = Card.last
      product.update!(price: 250)
      client.update!(payout_rate: 0.5)

      expect(card.reload.purchase_amount).to eq(80)
    end

    it "returns forbidden when client has no product access" do
      inaccessible = Product.create!(brand: brand, name: "Other Card", price: 50, status: :active)

      expect {
        post "/api/v1/cards",
             params: { card: { product_id: inaccessible.id } },
             headers: auth_headers(client),
             as: :json
      }.not_to change(Card, :count)

      expect(response).to have_http_status(:forbidden)
      expect(json_body["error"]).to eq("Forbidden")
      expect(json_body["message"]).to eq("You do not have access to this product")
    end

    it "returns unprocessable when product is inactive" do
      product.update!(status: :inactive)

      expect {
        post "/api/v1/cards",
             params: { card: { product_id: product.id } },
             headers: auth_headers(client),
             as: :json
      }.not_to change(Card, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body).to eq(
        "error" => "Unprocessable Entity",
        "message" => "Product is not active"
      )
    end

    it "returns not found when product does not exist" do
      expect {
        post "/api/v1/cards",
             params: { card: { product_id: 0 } },
             headers: auth_headers(client),
             as: :json
      }.not_to change(Card, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "forbids admin from issuing cards" do
      expect {
        post "/api/v1/cards",
             params: { card: { product_id: product.id } },
             headers: auth_headers(admin),
             as: :json
      }.not_to change(Card, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/v1/cards", params: { card: { product_id: product.id } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/cards" do
    def issue_card_for!(user, assigned_product = product)
      ClientProduct.find_or_create_by!(client: user, product: assigned_product)
      IssueCard.new(client: user, product_id: assigned_product.id).call
    end

    it "returns only the current client's cards" do
      own_card = issue_card_for!(client)
      issue_card_for!(other_client)

      get "/api/v1/cards", headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:ok)
      ids = json_body["cards"].map { |c| c["id"] }
      expect(ids).to eq([ own_card.id ])
      expect(json_body["cards"].first).to include(
        "client_id" => client.id,
        "product_id" => product.id,
        "status" => "issued"
      )
    end

    it "returns an empty list when the client has no cards" do
      get "/api/v1/cards", headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["cards"]).to eq([])
    end

    it "forbids admin from listing cards" do
      get "/api/v1/cards", headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/cards", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/cards/:id/cancel" do
    def issue_card_for!(user, assigned_product = product)
      ClientProduct.find_or_create_by!(client: user, product: assigned_product)
      IssueCard.new(client: user, product_id: assigned_product.id).call
    end

    it "cancels an issued card owned by the current client" do
      card = issue_card_for!(client)

      patch "/api/v1/cards/#{card.id}/cancel", headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["card"]).to include(
        "id" => card.id,
        "status" => "cancelled"
      )
      expect(json_body["card"]["cancelled_at"]).to be_present

      card.reload
      expect(card).to be_cancelled
      expect(card.cancelled_at).to be_present
    end

    it "rejects cancelling an already cancelled card" do
      card = issue_card_for!(client)
      card.update!(status: :cancelled, cancelled_at: 1.hour.ago)

      patch "/api/v1/cards/#{card.id}/cancel", headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body).to eq(
        "error" => "Unprocessable Entity",
        "message" => "Card is already cancelled"
      )
      expect(card.reload.cancelled_at).to be_within(1.second).of(1.hour.ago)
    end

    it "forbids cancelling another client's card" do
      card = issue_card_for!(other_client)

      patch "/api/v1/cards/#{card.id}/cancel", headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(card.reload).to be_issued
    end

    it "forbids admin from cancelling cards" do
      card = issue_card_for!(client)

      patch "/api/v1/cards/#{card.id}/cancel", headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(card.reload).to be_issued
    end

    it "returns not found when card does not exist" do
      patch "/api/v1/cards/0/cancel", headers: auth_headers(client), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      card = issue_card_for!(client)

      patch "/api/v1/cards/#{card.id}/cancel", as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(card.reload).to be_issued
    end
  end
end
