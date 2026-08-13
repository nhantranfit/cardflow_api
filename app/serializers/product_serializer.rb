class ProductSerializer < ActiveModel::Serializer
  attributes :id, :brand_name, :name, :price, :status

  def brand_name
    object.brand.name
  end
end
