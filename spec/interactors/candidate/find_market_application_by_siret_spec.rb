# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::FindMarketApplicationBySiret, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }
  let(:market_application) { create(:market_application, public_market:, siret:) }

  describe '.call' do
    context 'when no market_application_id is provided' do
      it 'fails with a base error' do
        result = described_class.call(siret:, email: 'anyone@example.com', market_application_id: nil)

        expect(result).to be_failure
        expect(result.errors[:base]).to include(I18n.t('candidate.request_magic_link.no_market_context'))
      end
    end

    context 'when the SIRET does not match the identified application' do
      before { market_application }

      it 'fails with a base error' do
        result = described_class.call(siret: 'wrong_siret', email: 'anyone@example.com',
          market_application_id: market_application.identifier)

        expect(result).to be_failure
        expect(result.errors[:base]).to be_present
      end
    end

    context 'when the application is found (first access)' do
      before { market_application }

      it 'succeeds and sets reconnection to false' do
        result = described_class.call(siret:, email: 'anyone@example.com',
          market_application_id: market_application.identifier)

        expect(result).to be_success
        expect(result.reconnection).to be false
        expect(result.market_application).to eq(market_application)
      end
    end

    context 'when multiple applications exist for the same SIRET' do
      let(:other_public_market) { create(:public_market, :completed, editor:) }
      let(:other_application) { create(:market_application, public_market: other_public_market, siret:) }

      before { market_application && other_application }

      it 'finds the application matching the identifier' do
        result = described_class.call(siret:, email: 'anyone@example.com',
          market_application_id: other_application.identifier)

        expect(result).to be_success
        expect(result.market_application).to eq(other_application)
      end
    end

    context 'when a market application exists with a user (reconnection)' do
      let(:user) { create(:user, email: 'original@example.com') }

      before { market_application.update!(user:) }

      it 'succeeds when email matches' do
        result = described_class.call(siret:, email: 'original@example.com',
          market_application_id: market_application.identifier)

        expect(result).to be_success
        expect(result.reconnection).to be true
      end

      it 'succeeds when email matches with different casing' do
        result = described_class.call(siret:, email: 'ORIGINAL@EXAMPLE.COM',
          market_application_id: market_application.identifier)

        expect(result).to be_success
      end

      it 'fails when email does not match' do
        result = described_class.call(siret:, email: 'wrong@example.com',
          market_application_id: market_application.identifier)

        expect(result).to be_failure
        expect(result.errors[:email]).to be_present
      end
    end

    context 'when another application for the same SIRET on the same market already has a user' do
      let(:other_application) { create(:market_application, public_market:, siret:) }
      let(:user) { create(:user, email: 'original@example.com') }

      before do
        market_application
        other_application.update!(user:)
      end

      it 'fails when email does not match the existing user' do
        result = described_class.call(siret:, email: 'different@example.com',
          market_application_id: market_application.identifier)

        expect(result).to be_failure
        expect(result.errors[:email]).to be_present
      end

      it 'succeeds when email matches the existing user' do
        result = described_class.call(siret:, email: 'original@example.com',
          market_application_id: market_application.identifier)

        expect(result).to be_success
        expect(result.reconnection).to be true
      end
    end

    context 'when another application for the same SIRET on a different market already has a user' do
      let(:other_public_market) { create(:public_market, :completed, editor:) }
      let(:other_application) { create(:market_application, public_market: other_public_market, siret:) }
      let(:user) { create(:user, email: 'original@example.com') }

      before do
        market_application
        other_application.update!(user:)
      end

      it 'succeeds with a different email' do
        result = described_class.call(siret:, email: 'different@example.com',
          market_application_id: market_application.identifier)

        expect(result).to be_success
        expect(result.reconnection).to be false
      end
    end
  end
end
