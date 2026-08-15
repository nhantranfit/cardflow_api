require "rails_helper"

RSpec.describe "Api::V1::Reports", type: :request do
  let(:admin) { create_user(email: "ops.admin@cardflow.com", role: :admin) }
  let(:client) { create_user(email: "lan.nguyen@retailhub.vn", role: :client, payout_rate: 0.8) }
  let(:other_client) { create_user(email: "minh.tran@shopmart.vn", role: :client, payout_rate: 0.75) }
  let!(:adidas) { Brand.create!(name: "Adidas", description: "Sportswear", status: :active) }
  let!(:nike) { Brand.create!(name: "Nike", description: "Just Do It", status: :active) }
  let!(:adidas_product) { Product.create!(brand: adidas, name: "Adidas Gift Card 100", price: 100, status: :active) }
  let!(:nike_product) { Product.create!(brand: nike, name: "Nike Gift Card 100", price: 100, status: :active) }

  def issue_for!(user, product = adidas_product)
    ClientProduct.find_or_create_by!(client: user, product: product)
    IssueCard.new(client: user, product_id: product.id).call
  end

  def report_items
    json_body["reports"]
  end

  describe "GET /api/v1/reports" do
    context "as client" do
      it "returns operation reports for the current client's cards" do
        issued = issue_for!(client)
        cancelled = issue_for!(client)
        cancelled.update!(status: :cancelled, cancelled_at: 1.hour.ago)
        issue_for!(other_client)

        get "/api/v1/reports", headers: auth_headers(client)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(2)

        issued_row = report_items.find { |row| row["operation"] == "Issued" }
        cancelled_row = report_items.find { |row| row["operation"] == "Cancelled" }

        expect(issued_row).to include(
          "client" => client.email,
          "brand_name" => adidas.name,
          "product_name" => adidas_product.name,
          "amount" => 80.0
        )
        expect(Time.zone.parse(issued_row["date"])).to be_within(1.second).of(issued.created_at)

        expect(cancelled_row).to include(
          "client" => client.email,
          "brand_name" => adidas.name,
          "product_name" => adidas_product.name,
          "amount" => 80.0
        )
        expect(Time.zone.parse(cancelled_row["date"])).to be_within(1.second).of(cancelled.cancelled_at)
      end

      it "filters issued cards with status=spending" do
        issued = issue_for!(client)
        cancelled = issue_for!(client)
        cancelled.update!(status: :cancelled, cancelled_at: Time.current)

        get "/api/v1/reports", params: { status: "spending" }, headers: auth_headers(client)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(1)
        expect(report_items.first).to include(
          "operation" => "Issued",
          "client" => client.email,
          "brand_name" => adidas.name,
          "product_name" => adidas_product.name,
          "amount" => 80.0
        )
        expect(Time.zone.parse(report_items.first["date"])).to be_within(1.second).of(issued.created_at)
      end

      it "filters cancelled cards with status=cancellations" do
        issue_for!(client)
        cancelled = issue_for!(client)
        cancelled.update!(status: :cancelled, cancelled_at: Time.current)

        get "/api/v1/reports", params: { status: "cancellations" }, headers: auth_headers(client)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(1)
        expect(report_items.first).to include(
          "operation" => "Cancelled",
          "client" => client.email,
          "brand_name" => adidas.name,
          "product_name" => adidas_product.name,
          "amount" => 80.0
        )
        expect(Time.zone.parse(report_items.first["date"])).to be_within(1.second).of(cancelled.cancelled_at)
      end

      it "ignores brand_id and client_id params" do
        issue_for!(client)
        issue_for!(other_client)

        get "/api/v1/reports",
            params: { brand_id: adidas.id, client_id: other_client.id },
            headers: auth_headers(client)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(1)
        expect(report_items.first["client"]).to eq(client.email)
      end
    end

    context "as admin" do
      it "returns reports across clients" do
        issue_for!(client, adidas_product)
        issue_for!(other_client, nike_product)

        get "/api/v1/reports", headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(2)
        expect(report_items.map { |row| row["client"] }).to contain_exactly(client.email, other_client.email)
        expect(report_items.map { |row| row["brand_name"] }).to contain_exactly(adidas.name, nike.name)
      end

      it "filters by brand_id" do
        issue_for!(client, adidas_product)
        issue_for!(other_client, nike_product)

        get "/api/v1/reports", params: { brand_id: adidas.id }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(1)
        expect(report_items.first).to include(
          "client" => client.email,
          "brand_name" => adidas.name,
          "product_name" => adidas_product.name
        )
      end

      it "filters by client_id" do
        issue_for!(client, adidas_product)
        issue_for!(other_client, nike_product)

        get "/api/v1/reports", params: { client_id: other_client.id }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(1)
        expect(report_items.first).to include(
          "client" => other_client.email,
          "brand_name" => nike.name
        )
      end

      it "filters by brand_id and client_id together" do
        matching = issue_for!(client, adidas_product)
        issue_for!(client, nike_product)
        issue_for!(other_client, adidas_product)

        get "/api/v1/reports",
            params: { brand_id: adidas.id, client_id: client.id },
            headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(1)
        expect(report_items.first).to include(
          "client" => client.email,
          "brand_name" => adidas.name,
          "product_name" => adidas_product.name,
          "amount" => matching.purchase_amount.to_f
        )
      end

      it "filters by status=spending" do
        issue_for!(client, adidas_product)
        cancelled = issue_for!(other_client, nike_product)
        cancelled.update!(status: :cancelled, cancelled_at: Time.current)

        get "/api/v1/reports", params: { status: "spending" }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(report_items.size).to eq(1)
        expect(report_items.first["operation"]).to eq("Issued")
      end

      it "returns not found for an unknown brand_id" do
        get "/api/v1/reports", params: { brand_id: 0 }, headers: auth_headers(admin)

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found for an unknown client_id" do
        get "/api/v1/reports", params: { client_id: 0 }, headers: auth_headers(admin)

        expect(response).to have_http_status(:not_found)
      end
    end

    it "requires authentication" do
      get "/api/v1/reports"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
