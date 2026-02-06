# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocleDeBasePresenter do
  let(:market_attribute) do
    build(:market_attribute,
      key: 'identite_entreprise_identification_siret',
      category_key: 'identite_entreprise',
      subcategory_key: 'identite_entreprise_identification')
  end
  let(:presenter) { described_class.new(market_attribute) }

  describe '#buyer_name' do
    it 'returns the buyer field name from i18n' do
      expect(presenter.buyer_name).to eq('SIRET')
    end

    context 'when key has no translation' do
      let(:market_attribute) { build(:market_attribute, key: 'unknown_key') }

      it 'returns humanized key as fallback' do
        expect(presenter.buyer_name).to eq('Unknown key')
      end
    end
  end

  describe '#candidate_name' do
    it 'returns the candidate field name from i18n' do
      expect(presenter.candidate_name).to eq('SIRET')
    end
  end
end
