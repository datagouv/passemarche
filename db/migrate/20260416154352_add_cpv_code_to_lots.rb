class AddCpvCodeToLots < ActiveRecord::Migration[8.1]
  def change
    add_column :lots, :cpv_code, :string
  end
end
