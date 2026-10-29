# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteMarketApplication, type: :interactor do
  let(:market_application) { create(:market_application) }

  describe '.call' do
    subject { described_class.call(market_application:) }

    context 'when market application is in progress' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'destroys the market application' do
        market_application
        expect { subject }.to change(MarketApplication, :count).by(-1)
      end

      context 'when no other application exists for same user and siret' do
        it 'returns nil as next_application' do
          expect(subject.next_application).to be_nil
        end
      end

      context 'when market application has no user' do
        let(:market_application) { create(:market_application, user: nil) }

        it 'returns nil as next_application' do
          expect(subject.next_application).to be_nil
        end
      end

      context 'when another application exists for same user and siret' do
        let(:user) { create(:user) }
        let(:market_application) { create(:market_application, user:) }
        let!(:other_application) do
          create(:market_application, user:, siret: market_application.siret)
        end

        it 'returns the other application as next_application' do
          expect(subject.next_application).to eq(other_application)
        end
      end
    end

    context 'when market application is a grouping application whose grouping is not created yet' do
      let(:market_application) { create(:market_application, application_mode: :groupement) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'does not destroy the market application' do
        market_application
        expect { subject }.not_to change(MarketApplication, :count)
      end
    end

    context 'when market application belongs to a grouping' do
      before { allow(SiretValidator).to receive(:valid?).and_return(true) }

      let(:public_market) { create(:public_market, :completed) }
      let(:mandataire_application) do
        create(:market_application, public_market:, siret: '41816609600069', application_mode: :groupement)
      end
      let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }

      context 'when the candidate is co-traitant' do
        let(:market_application) { create(:market_application, public_market:, application_mode: :groupement) }

        before do
          create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
        end

        it 'fails' do
          expect(subject).to be_failure
        end

        it 'does not destroy the market application' do
          expect { subject }.not_to change(MarketApplication, :count)
        end
      end

      context 'when the candidate is mandataire' do
        let(:market_application) { mandataire_application }

        before { grouping }

        it 'fails' do
          expect(subject).to be_failure
        end

        it 'does not destroy the market application' do
          expect { subject }.not_to change(MarketApplication, :count)
        end
      end
    end

    context 'when market application is completed (transmitted)' do
      let(:market_application) { create(:market_application, :completed) }

      it 'fails' do
        expect(subject).to be_failure
      end
    end
  end
end
