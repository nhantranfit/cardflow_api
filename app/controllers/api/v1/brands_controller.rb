module Api
  module V1
    class BrandsController < ApplicationController
      before_action :set_brand, only: %i[update destroy]

      def index
        authorize Brand
        render json: Brand.order(:name), each_serializer: BrandSerializer
      end

      def create
        authorize Brand
        brand = Brand.new(brand_params)

        if brand.save
          log_action("create", brand)
          render json: brand, serializer: BrandSerializer, status: :created
        else
          render_validation_errors(brand)
        end
      end

      def update
        authorize @brand

        if @brand.update(brand_params)
          log_action("update", @brand)
          render json: @brand, serializer: BrandSerializer
        else
          render_validation_errors(@brand)
        end
      end

      def destroy
        authorize @brand

        if @brand.destroy
          log_action("destroy", @brand)
          render json: { message: "Brand deleted successfully" }, status: :ok
        else
          render_validation_errors(@brand)
        end
      end

      private

      def set_brand
        @brand = Brand.find(params[:id])
      end

      def brand_params
        params.require(:brand).permit(:name, :description, :status)
      end
    end
  end
end
