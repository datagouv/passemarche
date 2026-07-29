class CreateGroupings < ActiveRecord::Migration[8.1]
  def change
    create_table :groupings do |t|
      t.references :public_market, null: false, foreign_key: true
      t.references :mandataire_market_application, null: false, foreign_key: { to_table: :market_applications }
      t.string :mandataire_siret, null: false
      t.integer :legal_type

      t.timestamps
    end

    add_index :groupings, %i[public_market_id mandataire_market_application_id], unique: true,
      name: 'index_groupings_on_market_and_mandataire'
    add_index :groupings, %i[public_market_id mandataire_siret], unique: true,
      name: 'index_groupings_on_market_and_mandataire_siret'
  end
end
