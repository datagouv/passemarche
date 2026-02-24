# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeCreationService do
  let(:works_type) { create(:market_type, :works) }
  let(:services_type) { create(:market_type, :services) }
  let(:category) { create(:category, key: 'identite_entreprise') }
  let(:subcategory) { create(:subcategory, key: 'identite_identification', category:) }

  let(:valid_manual_params) do
    {
      input_type: 'text_input',
      mandatory: true,
      configuration_mode: 'manual',
      subcategory_id: subcategory.id.to_s,
      buyer_name: 'Numéro SIRET',
      candidate_name: 'Votre SIRET',
      buyer_description: 'Identifiant SIRET de l\'entreprise',
      candidate_description: 'Renseignez votre numéro SIRET',
      market_type_ids: [works_type.id.to_s, services_type.id.to_s]
    }
  end

  let(:valid_api_params) do
    valid_manual_params.merge(
      configuration_mode: 'api',
      api_name: 'Insee',
      api_key: 'siret'
    )
  end

  describe '#perform' do
    context 'with valid manual params' do
      subject do
        service = described_class.new(params: valid_manual_params)
        service.perform
        service
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates a market attribute' do
        expect { subject }.to change(MarketAttribute, :count).by(1)
      end

      it 'generates key from buyer_name' do
        expect(subject.result.key).to eq('numero_siret')
      end

      it 'assigns market types' do
        expect(subject.result.market_types).to include(works_type, services_type)
      end

      it 'sets api_name to nil for manual source' do
        expect(subject.result.api_name).to be_nil
      end

      it 'resolves subcategory_id' do
        expect(subject.result.subcategory_id).to eq(subcategory.id)
      end

      it 'resolves category_key from subcategory' do
        expect(subject.result.category_key).to eq(category.key)
      end

      it 'resolves subcategory_key from subcategory' do
        expect(subject.result.subcategory_key).to eq(subcategory.key)
      end

      it 'auto-calculates position' do
        expect(subject.result.position).to eq(1)
      end
    end

    context 'with valid API params' do
      subject do
        service = described_class.new(params: valid_api_params)
        service.perform
        service
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets api_name and api_key' do
        expect(subject.result.api_name).to eq('Insee')
        expect(subject.result.api_key).to eq('siret')
      end
    end

    context 'with missing market types' do
      subject do
        service = described_class.new(params: valid_manual_params.merge(market_type_ids: []))
        service.perform
        service
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has an error on market_types' do
        expect(subject.errors).to have_key(:market_types)
      end
    end

    context 'with missing buyer_name' do
      subject do
        service = described_class.new(params: valid_manual_params.merge(buyer_name: ''))
        service.perform
        service
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has an error on buyer_name' do
        expect(subject.errors).to have_key(:buyer_name)
      end
    end

    context 'with API source missing api_name' do
      subject do
        service = described_class.new(params: valid_api_params.merge(api_name: ''))
        service.perform
        service
      end

      it 'fails' do
        expect(subject).to be_failure
      end
    end

    context 'with existing attributes in subcategory' do
      before do
        create(:market_attribute,
          category_key: category.key,
          subcategory_key: subcategory.key,
          position: 5)
      end

      it 'assigns position after the last one' do
        service = described_class.new(params: valid_manual_params)
        service.perform
        expect(service.result.position).to eq(6)
      end
    end
  end
end
