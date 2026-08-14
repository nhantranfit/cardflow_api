class CardSerializer < ActiveModel::Serializer
  attributes :id, :client_id, :product_id, :activation_number, :pin, :purchase_amount, :status, :cancelled_at
end
