class CreateClientProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :client_products do |t|
      t.references :client, null: false,foreign_key: { to_table: :users }
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end

    add_index :client_products, [:client_id, :product_id], unique: true
  end
end
