class CreateBrands < ActiveRecord::Migration[7.1]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :brands, :name, unique: true

    add_check_constraint :brands, "status IN (0, 1)", name: "brands_status_check"
  end
end
