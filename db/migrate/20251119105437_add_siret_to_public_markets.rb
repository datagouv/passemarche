class AddSiretToPublicMarkets < ActiveRecord::Migration[8.1]
  DINUM_SIRET = '13002526500013'.freeze

  def up
    add_column :public_markets, :siret, :string, null: true
    add_index :public_markets, :siret

    reversible do |dir|
      dir.up do
        PublicMarket.find_each do |market|
          # rubocop:disable Rails/SkipsModelValidations
          market.update_column(:siret, DINUM_SIRET) if market.siret.blank?
          # rubocop:enable Rails/SkipsModelValidations
        end
      end
    end

    change_column_null :public_markets, :siret, false
  end

  def down
    remove_index :public_markets, :siret
    remove_column :public_markets, :siret
  end
end
