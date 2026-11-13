class DeviseCreateLearners < ActiveRecord::Migration[8.1]
  def change
    create_table :learners do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      t.datetime :remember_created_at

      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email

      t.string :full_name, null: false
      t.integer :gender, null: false

      t.timestamps null: false
    end

    add_index :learners, :email, unique: true
    add_index :learners, :reset_password_token, unique: true
    add_index :learners, :confirmation_token, unique: true
  end
end
