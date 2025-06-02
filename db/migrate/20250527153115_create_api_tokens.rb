class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.string :token
      t.references :user, null: false, foreign_key: true
      t.string :purpose
      t.datetime :last_used_at
      t.datetime :expires_at
      t.boolean :active

      t.timestamps
    end
    add_index :api_tokens, :token, unique: true
  end
end
