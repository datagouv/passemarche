# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeUpdateService do
  let(:category) { create(:category, key: 'identity', buyer_label: 'Identity', candidate_label: 'Identity') }
  let(:subcategory) { create(:subcategory, category:, key: 'basic') }
  let(:supplies) { create(:market_type, code: 'supplies') }
  let(:services) { create(:market_type, :services) }
  let(:market_attribute) do
    create(:market_attribute,
      key: 'test_field', subcategory:,
      input_type: :text_input, mandatory: false).tap { |a| a.market_types << supplies }
  end

  describe '#perform' do
    it 'updates basic fields' do
      service = described_class.new(
        market_attribute:,
        params: { input_type: 'textarea', mandatory: true }
      )
      service.perform

      expect(service).to be_success
      market_attribute.reload
      expect(market_attribute.input_type).to eq('textarea')
      expect(market_attribute).to be_mandatory
    end

    it 'syncs market type associations' do
      service = described_class.new(
        market_attribute:,
        params: { market_type_ids: [services.id.to_s] }
      )
      service.perform

      expect(service).to be_success
      expect(market_attribute.reload.market_types).to contain_exactly(services)
    end

    it 'clears api fields when configuration_mode is manual' do
      market_attribute.update!(api_name: 'TestAPI', api_key: 'key')

      service = described_class.new(
        market_attribute:,
        params: { configuration_mode: 'manual' }
      )
      service.perform

      expect(service).to be_success
      market_attribute.reload
      expect(market_attribute.api_name).to be_nil
      expect(market_attribute.api_key).to be_nil
    end

    it 'sets api fields when configuration_mode is api' do
      service = described_class.new(
        market_attribute:,
        params: { configuration_mode: 'api', api_name: 'NewAPI', api_key: 'new_key' }
      )
      service.perform

      expect(service).to be_success
      market_attribute.reload
      expect(market_attribute.api_name).to eq('NewAPI')
      expect(market_attribute.api_key).to eq('new_key')
    end

    it 'requires api_name when configuration_mode is api' do
      service = described_class.new(
        market_attribute:,
        params: { configuration_mode: 'api', api_name: '' }
      )
      service.perform

      expect(service).to be_failure
      expect(service.errors).to have_key(:api_name)
    end

    it 'returns failure on validation error' do
      service = described_class.new(
        market_attribute:,
        params: { key: '' }
      )
      service.perform

      expect(service).to be_failure
      expect(service.errors).to have_key(:key)
    end

    it 'rolls back market types on validation failure' do
      service = described_class.new(
        market_attribute:,
        params: { key: '', market_type_ids: [services.id.to_s] }
      )
      service.perform

      expect(market_attribute.reload.market_types).to contain_exactly(supplies)
    end

    it 'updates buyer and candidate fields' do
      service = described_class.new(
        market_attribute:,
        params: {
          buyer_name: 'Nom acheteur',
          buyer_description: 'Description acheteur',
          candidate_name: 'Nom candidat',
          candidate_description: 'Description candidat'
        }
      )
      service.perform

      expect(service).to be_success
      market_attribute.reload
      expect(market_attribute.buyer_name).to eq('Nom acheteur')
      expect(market_attribute.buyer_description).to eq('Description acheteur')
      expect(market_attribute.candidate_name).to eq('Nom candidat')
      expect(market_attribute.candidate_description).to eq('Description candidat')
    end
  end
end
