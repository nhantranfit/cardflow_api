class ClientSerializer < ActiveModel::Serializer
  attributes :id, :email, :role, :payout_rate
end
