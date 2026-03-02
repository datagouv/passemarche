# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.datetime :authentication_token_sent_at

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
