class BrandSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :status
end
