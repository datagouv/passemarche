# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocleDeBaseStatsService, type: :service do
  describe '#call' do
    before do
      MarketAttribute.delete_all
    end

    context 'with no attributes' do
      it 'returns zeros for all stats' do
        result = described_class.call

        expect(result.total_count).to eq(0)
        expect(result.api_count).to eq(0)
        expect(result.manual_count).to eq(0)
        expect(result.mandatory_count).to eq(0)
      end
    end

    context 'with various attributes' do
      before do
        create(:market_attribute, mandatory: true, api_name: 'Insee', api_key: 'siret')
        create(:market_attribute, mandatory: true, api_name: nil)
        create(:market_attribute, mandatory: false, api_name: 'Rne', api_key: 'rne')
        create(:market_attribute, mandatory: false, api_name: nil)
        create(:market_attribute, :inactive)
      end

      it 'returns correct total count (excludes inactive)' do
        result = described_class.call

        expect(result.total_count).to eq(4)
      end

      it 'returns correct api count' do
        result = described_class.call

        expect(result.api_count).to eq(2)
      end

      it 'returns correct manual count' do
        result = described_class.call

        expect(result.manual_count).to eq(2)
      end

      it 'returns correct mandatory count' do
        result = described_class.call

        expect(result.mandatory_count).to eq(2)
      end
    end

    context 'with only api attributes' do
      before do
        create(:market_attribute, api_name: 'Insee', api_key: 'siret')
        create(:market_attribute, api_name: 'Rne', api_key: 'rne')
      end

      it 'returns zero for manual count' do
        result = described_class.call

        expect(result.manual_count).to eq(0)
      end
    end

    context 'with only manual attributes' do
      before do
        create(:market_attribute, api_name: nil)
        create(:market_attribute, api_name: nil)
      end

      it 'returns zero for api count' do
        result = described_class.call

        expect(result.api_count).to eq(0)
      end

      it 'returns total equal to manual count' do
        result = described_class.call

        expect(result.manual_count).to eq(result.total_count)
      end
    end
  end
end
