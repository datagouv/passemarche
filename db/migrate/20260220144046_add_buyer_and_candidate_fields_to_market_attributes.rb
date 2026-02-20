class AddBuyerAndCandidateFieldsToMarketAttributes < ActiveRecord::Migration[8.1]
  def change
    change_table :market_attributes, bulk: true do |t|
      t.string :buyer_name, if_not_exists: true
      t.text :buyer_description, if_not_exists: true
      t.string :candidate_name, if_not_exists: true
      t.text :candidate_description, if_not_exists: true
    end
  end
end
