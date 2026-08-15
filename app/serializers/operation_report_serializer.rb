class OperationReportSerializer < ActiveModel::Serializer
  attributes :date, :operation, :client, :brand_name, :product_name, :amount

  def date
    object.issued? ? object.created_at : object.cancelled_at
  end

  def operation
    object.issued? ? "Issued" : "Cancelled"
  end

  def client
    object.client.email
  end

  def brand_name
    object.product.brand.name
  end

  def product_name
    object.product.name
  end

  def amount
    object.purchase_amount.to_f
  end
end
