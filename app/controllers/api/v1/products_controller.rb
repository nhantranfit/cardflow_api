module Api
  module V1
    class ProductsController < ApplicationController
      before_action :set_product, only: %i[update destroy]

      def index
        authorize Product

        products = if current_user.admin?
                     admin_products
                   else
                    ProductCatalogQuery.new(
                      user: current_user,
                      params: params
                    ).call
                   end

        render json: products, each_serializer: ProductSerializer
      end

      def create
        authorize Product
        product = Product.new(product_params)

        if product.save
          render json: product, serializer: ProductSerializer, status: :created
        else
          render_validation_errors(product)
        end
      end

      def update
        authorize @product

        if @product.update(product_params)
          render json: @product, serializer: ProductSerializer
        else
          render_validation_errors(@product)
        end
      end

      def destroy
        authorize @product

        if @product.destroy
          render json: { message: "Product deleted successfully" }, status: :ok
        else
          render_validation_errors(@product)
        end
      end

      private

      def admin_products
        Product.includes(:brand).order(:name)
      end

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        params.require(:product).permit(:brand_id, :name, :price, :status)
      end
    end
  end
end
