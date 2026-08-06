class AddCompanyNameToGroupingMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :grouping_members, :company_name, :string
  end
end
