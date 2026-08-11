class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false
      t.decimal :payout_rate, precision: 5, scale: 4

      t.timestamps
    end

    add_index :users, :email, unique: true

    add_check_constraint :users, "role IN ('admin', 'client')", name: "users_role_check"
    add_check_constraint :users,
      "(role = 'admin' AND payout_rate IS NULL) OR " \
      "(role = 'client' AND payout_rate IS NOT NULL AND payout_rate > 0 AND payout_rate <= 1)",
      name: "users_payout_rate_role_check"
  end
end
