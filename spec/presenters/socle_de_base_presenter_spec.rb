# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocleDeBasePresenter do
  let(:category) do
    create(:category, key: 'identite_entreprise',
      buyer_label: "Identité de l'entreprise",
      candidate_label: 'Les informations du marché et de votre entreprise')
  end
  let(:subcategory) do
    create(:subcategory, category:, key: 'identite_entreprise_identification',
      buyer_label: "Identification de l'entreprise",
      candidate_label: 'Informations de votre entreprise')
  end
  let(:market_attribute) do
    build(:market_attribute,
      key: 'identite_entreprise_identification_siret',
      category_key: 'identite_entreprise',
      subcategory_key: 'identite_entreprise_identification',
      subcategory:,
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
    it 'returns the buyer label from the category record' do
      expect(presenter.buyer_category_label).to eq("Identité de l'entreprise")
    end

    context 'when subcategory is nil' do
      let(:market_attribute) { build(:market_attribute, subcategory: nil, category_key: 'identite_entreprise') }

      it 'falls back to humanized category_key' do
        expect(presenter.buyer_category_label).to eq('Identite entreprise')
      end
    end
  end

  describe '#buyer_subcategory_label' do
    it 'returns the buyer label from the subcategory record' do
      expect(presenter.buyer_subcategory_label).to eq("Identification de l'entreprise")
    end

    context 'when subcategory is nil' do
      let(:market_attribute) { build(:market_attribute, subcategory: nil, subcategory_key: 'some_key') }

      it 'falls back to humanized subcategory_key' do
        expect(presenter.buyer_subcategory_label).to eq('Some key')
      end
    end
  end

  describe '#candidate_category_label' do
    it 'returns the candidate label from the category record' do
      expect(presenter.candidate_category_label).to eq('Les informations du marché et de votre entreprise')
    end
  end

  describe '#candidate_subcategory_label' do
    it 'returns the candidate label from the subcategory record' do
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

  describe '#category_label' do
    it 'delegates to buyer_category_label' do
      expect(presenter.category_label).to eq(presenter.buyer_category_label)
    end
  end

  describe '#subcategory_label' do
    it 'delegates to buyer_subcategory_label' do
      expect(presenter.subcategory_label).to eq(presenter.buyer_subcategory_label)
    end
  end

  describe '#field_name' do
    it 'delegates to buyer_name' do
      expect(presenter.field_name).to eq(presenter.buyer_name)
    end
  end

  describe '#market_type_badges' do
    let(:market_attribute) do
      create(:market_attribute,
        key: 'test_field_badges',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification')
    end

    context 'when attribute has works and supplies market types' do
      before do
        create(:market_type, :works)
        create(:market_type)
        create(:market_type, :services)
        market_attribute.market_types << MarketType.where(code: %w[works supplies])
      end

      it 'returns T and F as active, S as inactive' do
        badges = presenter.market_type_badges

        expect(badges).to eq([
          { letter: 'T', code: 'works', active: true },
          { letter: 'F', code: 'supplies', active: true },
          { letter: 'S', code: 'services', active: false }
        ])
      end
    end

    context 'when attribute has no market types' do
      it 'returns all badges as inactive' do
        badges = presenter.market_type_badges

        expect(badges).to all(include(active: false))
      end
    end

    context 'when attribute has all three market types' do
      before do
        create(:market_type, :works)
        create(:market_type)
        create(:market_type, :services)
        market_attribute.market_types << MarketType.where(code: %w[works supplies services])
      end

      it 'returns all badges as active' do
        badges = presenter.market_type_badges

        expect(badges).to all(include(active: true))
      end
    end
  end
end
