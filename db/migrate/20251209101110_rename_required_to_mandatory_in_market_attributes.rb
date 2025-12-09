class RenameRequiredToMandatoryInMarketAttributes < ActiveRecord::Migration[8.1]
  def change
    rename_column :market_attributes, :required, :mandatory
  end
end
