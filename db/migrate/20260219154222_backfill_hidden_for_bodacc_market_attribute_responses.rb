class BackfillHiddenForBodaccMarketAttributeResponses < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE market_attribute_responses
      SET hidden = true
      WHERE market_attribute_id IN (
        SELECT id FROM market_attributes WHERE api_name = 'bodacc'
      )
    SQL
  end

  def down
    execute <<~SQL
      UPDATE market_attribute_responses
      SET hidden = false
      WHERE market_attribute_id IN (
        SELECT id FROM market_attributes WHERE api_name = 'bodacc'
      )
    SQL
  end
end
