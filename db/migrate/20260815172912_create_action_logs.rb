class CreateActionLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :action_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.references :resource, polymorphic: true, null: false

      t.timestamps
    end
  end
end
