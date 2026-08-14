class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :product, null: false, foreign_key: true
      t.string :activation_number, null: false
      t.string :pin
      t.decimal :purchase_amount, precision: 12, scale: 2, null: false
      t.integer :status, null: false, default: 0
      t.datetime :cancelled_at, null: true

      t.timestamps
    end

    add_index :cards, :activation_number, unique: true
    add_check_constraint :cards, "status IN (0, 1)", name: "cards_status_check"
    add_check_constraint :cards, "purchase_amount > 0", name: "cards_purchase_amount_check"
  end
end
