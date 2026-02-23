class AddBuyerAndCandidateFieldsToMarketAttributes < ActiveRecord::Migration[8.1]
  def change
    change_table :market_attributes, bulk: true do |t|
      t.string :buyer_name unless t.column_exists?(:buyer_name)
      t.text :buyer_description unless t.column_exists?(:buyer_description)
      t.string :candidate_name unless t.column_exists?(:candidate_name)
      t.text :candidate_description unless t.column_exists?(:candidate_description)
    end
  end
end
