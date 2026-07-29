# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::ValidateApplicationMode, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    context 'when application_mode is solo' do
      it 'succeeds regardless of existing groupings' do
        result = described_class.call(public_market:, siret:, application_mode: 'solo')

        expect(result).to be_success
      end
    end

    context 'when application_mode is not a recognized value' do
      it 'fails for a garbage string' do
        result = described_class.call(public_market:, siret:, application_mode: 'invalid_garbage')

        expect(result).to be_failure
        expect(result.errors[:application_mode]).to be_present
      end

      it 'fails for a blank value' do
        result = described_class.call(public_market:, siret:, application_mode: '')

        expect(result).to be_failure
      end

      it 'fails for a nil value' do
        result = described_class.call(public_market:, siret:, application_mode: nil)

        expect(result).to be_failure
      end
    end

    context 'when application_mode is groupement or mixte' do
      context 'when the SIRET is not already mandataire on this market' do
        it 'succeeds' do
          result = described_class.call(public_market:, siret:, application_mode: 'groupement')

          expect(result).to be_success
        end
      end

      context 'when the SIRET is already mandataire of a grouping on this market' do
        before do
          mandataire_application = create(:market_application, public_market:, siret:, application_mode: :groupement)
          create(:grouping, public_market:, mandataire_market_application: mandataire_application)
        end

        it 'fails' do
          result = described_class.call(public_market:, siret:, application_mode: 'groupement')

          expect(result).to be_failure
        end

        it 'returns an explanatory error' do
          result = described_class.call(public_market:, siret:, application_mode: 'mixte')

          expect(result.errors[:application_mode]).to be_present
        end
      end

      context 'when the SIRET is mandataire of a grouping on a different market' do
        it 'succeeds' do
          other_market = create(:public_market, :completed, editor:)
          mandataire_application = create(:market_application, public_market: other_market, siret:,
            application_mode: :groupement)
          create(:grouping, public_market: other_market, mandataire_market_application: mandataire_application)

          result = described_class.call(public_market:, siret:, application_mode: 'groupement')

          expect(result).to be_success
        end
      end
    end
  end
end
