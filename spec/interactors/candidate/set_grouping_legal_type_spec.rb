# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::SetGroupingLegalType, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    context 'when the market_application is mandataire of a grouping' do
      let!(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil) }

      %w[conjoint solidaire conjoint_mandataire_solidaire].each do |legal_type|
        it "sets legal_type to #{legal_type}" do
          result = described_class.call(market_application:, legal_type:)

          expect(result).to be_success
          expect(grouping.reload.legal_type).to eq(legal_type)
        end
      end
    end

    context 'when legal_type is not a recognized value' do
      before { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil) }

      it 'fails for a garbage string' do
        result = described_class.call(market_application:, legal_type: 'invalid_garbage')

        expect(result).to be_failure
        expect(result.errors[:legal_type]).to be_present
      end

      it 'fails for a blank value' do
        result = described_class.call(market_application:, legal_type: '')

        expect(result).to be_failure
      end

      it 'fails for a nil value' do
        result = described_class.call(market_application:, legal_type: nil)

        expect(result).to be_failure
      end
    end

    context 'when the market_application is not mandataire of any grouping' do
      it 'fails' do
        result = described_class.call(market_application:, legal_type: 'conjoint')

        expect(result).to be_failure
        expect(result.errors[:grouping]).to be_present
      end
    end
  end
end
