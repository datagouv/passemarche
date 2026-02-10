class AddRoleToAdmins < ActiveRecord::Migration[8.1]
  def change
    add_column :admins, :role, :integer, default: 0, null: false
    add_index :admins, :role

    reversible do |dir|
      dir.up do
        execute 'UPDATE admins SET role = 1'
      end
    end
  end
end
