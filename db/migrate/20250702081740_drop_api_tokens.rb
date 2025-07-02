class DropApiTokens < ActiveRecord::Migration[8.0]
  def change
    drop_table :api_tokens do |t|
      t.string :token
      t.integer :user_id, null: false
      t.string :purpose
      t.datetime :last_used_at
      t.datetime :expires_at
      t.boolean :active
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :rate_limit, default: 100
      t.integer :requests_count, default: 0
      t.datetime :reset_at

      t.index :token, unique: true
      t.index :user_id
    end
  end
end
