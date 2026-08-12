class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :brand, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :products, "status IN (0, 1)", name: "products_status_check"
  end
end
