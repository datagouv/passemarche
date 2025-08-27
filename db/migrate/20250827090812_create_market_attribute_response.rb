class CreateMarketAttributeResponse < ActiveRecord::Migration[8.0]
  def change
    create_table :market_attribute_responses do |t|
      t.references :market_application, null: false
      t.references :market_attribute, null: false
      t.string :type, null: false
      t.jsonb :value, default: {}

      t.timestamps

      t.index %i[market_application_id market_attribute_id], unique: true
    end

    add_foreign_key :market_attribute_responses, :market_applications
    add_foreign_key :market_attribute_responses, :market_attributes
  end
end
