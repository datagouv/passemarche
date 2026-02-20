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

    it 'clears api fields when api_name is blank' do
      market_attribute.update!(api_name: 'TestAPI', api_key: 'key')

      service = described_class.new(
        market_attribute:,
        params: { api_name: '' }
      )
      service.perform

      expect(service).to be_success
      market_attribute.reload
      expect(market_attribute.api_name).to be_nil
      expect(market_attribute.api_key).to be_nil
    end

    it 'sets api fields when api_name is present' do
      service = described_class.new(
        market_attribute:,
        params: { api_name: 'NewAPI', api_key: 'new_key' }
      )
      service.perform

      expect(service).to be_success
      market_attribute.reload
      expect(market_attribute.api_name).to eq('NewAPI')
      expect(market_attribute.api_key).to eq('new_key')
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
  end
end
