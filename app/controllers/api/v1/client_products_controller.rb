module Api
  module V1
    class ClientProductsController < ApplicationController
      before_action :set_client
      before_action :set_product, only: :create
      before_action :set_client_product, only: :destroy

      def create
        authorize ClientProduct

        client_product = @client.client_products.build(product: @product)

        if client_product.save
          render json: client_product, serializer: ClientProductSerializer, status: :created
        else
          render_validation_errors(client_product)
        end
      end

      def destroy
        authorize @client_product

        if @client_product.destroy
          render json: { message: "Product deleted successfully" }, status: :ok
        else
          render_validation_errors(@client_product)
        end
      end

      private

      def set_client
        @client = User.client.find(params[:client_id])

      end

      def set_product
        @product = Product.find(params[:product_id])
      end

      def set_client_product
        @client_product = @client.client_products.find_by!(product_id: params[:product_id])
      end
    end
  end
end
