class CreateEditors < ActiveRecord::Migration[8.0]
  def change
    create_table :editors do |t|
      t.string :name, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.boolean :authorized, null: false, default: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :editors, :name, unique: true
    add_index :editors, :client_id, unique: true
  end
end
