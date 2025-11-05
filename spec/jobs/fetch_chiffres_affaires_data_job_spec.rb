# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchChiffresAffairesDataJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '41816609600069' }
  let(:market_application) { create(:market_application, public_market:, siret:) }

  describe '.api_name' do
    it 'returns dgfip_chiffres_affaires' do
      expect(described_class.api_name).to eq('dgfip_chiffres_affaires')
    end
  end

  describe '.api_service' do
    it 'returns ChiffresAffaires' do
      expect(described_class.api_service).to eq(ChiffresAffaires)
    end
  end

  describe '#perform' do
    context 'when DGFIP Chiffres d\'Affaires API succeeds' do
      it 'calls the ChiffresAffaires organizer with the correct parameters' do
        expect(ChiffresAffaires).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: true))

        described_class.new.perform(market_application.id)
      end
    end

    context 'when DGFIP Chiffres d\'Affaires API fails' do
      before do
        allow(ChiffresAffaires).to receive(:call).and_return(
          double(success?: false, error: 'API Error')
        )
      end

      it 'handles the failure gracefully' do
        expect { described_class.new.perform(market_application.id) }
          .not_to raise_error
      end
    end
  end
end
