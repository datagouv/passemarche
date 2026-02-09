# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocleDeBasePresenter do
  let(:market_attribute) do
    build(:market_attribute,
      key: 'identite_entreprise_identification_siret',
      category_key: 'identite_entreprise',
      subcategory_key: 'identite_entreprise_identification',
      mandatory: true,
      api_name: 'Insee')
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

  describe '#candidate_description' do
    context 'when description exists' do
      let(:market_attribute) do
        build(:market_attribute,
          key: 'motifs_exclusion_fiscales_et_sociales_liquidation_judiciaire',
          category_key: 'motifs_exclusion',
          subcategory_key: 'motifs_exclusion_fiscales_et_sociales')
      end

      it 'returns the candidate field description from i18n' do
        expect(presenter.candidate_description).to include('liquidation')
      end
    end

    context 'when description does not exist' do
      it 'returns nil' do
        expect(presenter.candidate_description).to be_nil
      end
    end
  end

  describe '#buyer_category_label' do
    it 'returns the buyer category label from i18n' do
      expect(presenter.buyer_category_label).to eq("Identité de l'entreprise")
    end
  end

  describe '#buyer_subcategory_label' do
    it 'returns the buyer subcategory label from i18n' do
      expect(presenter.buyer_subcategory_label).to eq("Identification de l'entreprise")
    end
  end

  describe '#candidate_category_label' do
    it 'returns the candidate category label from i18n' do
      expect(presenter.candidate_category_label).to eq('Les informations du marché et de votre entreprise')
    end
  end

  describe '#candidate_subcategory_label' do
    it 'returns the candidate subcategory label from i18n' do
      expect(presenter.candidate_subcategory_label).to eq('Informations de votre entreprise')
    end
  end

  describe '#mandatory_badge' do
    context 'when attribute is mandatory' do
      it 'returns "Obligatoire"' do
        expect(presenter.mandatory_badge).to eq('Obligatoire')
      end
    end

    context 'when attribute is optional' do
      let(:market_attribute) { build(:market_attribute, mandatory: false) }

      it 'returns "Complémentaire"' do
        expect(presenter.mandatory_badge).to eq('Complémentaire')
      end
    end
  end

  describe '#mandatory_badge_class' do
    context 'when attribute is mandatory' do
      it 'returns warning badge class' do
        expect(presenter.mandatory_badge_class).to eq('fr-badge--warning')
      end
    end

    context 'when attribute is optional' do
      let(:market_attribute) { build(:market_attribute, mandatory: false) }

      it 'returns new badge class' do
        expect(presenter.mandatory_badge_class).to eq('fr-badge--new')
      end
    end
  end

  describe '#source_badge' do
    context 'when attribute comes from API' do
      it 'returns "API {api_name}"' do
        expect(presenter.source_badge).to eq('API Insee')
      end
    end

    context 'when attribute is manual' do
      let(:market_attribute) { build(:market_attribute, api_name: nil) }

      it 'returns "Manuel"' do
        expect(presenter.source_badge).to eq('Manuel')
      end
    end
  end

  describe '#source_badge_class' do
    context 'when attribute comes from API' do
      it 'returns success badge class' do
        expect(presenter.source_badge_class).to eq('fr-badge--success')
      end
    end

    context 'when attribute is manual' do
      let(:market_attribute) { build(:market_attribute, api_name: nil) }

      it 'returns info badge class' do
        expect(presenter.source_badge_class).to eq('fr-badge--info')
      end
    end
  end
end
