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

    context 'when market application is completed (transmitted)' do
      let(:market_application) { create(:market_application, :completed) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides error message' do
        expect(subject.message).to eq('Impossible de supprimer une candidature transmise')
      end
    end
  end
end
