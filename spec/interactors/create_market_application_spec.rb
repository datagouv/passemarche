# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateMarketApplication, type: :interactor do
  let(:editor) { create(:editor) }
  let(:siret) { '73282932000074' }

  before do
    allow(SiretValidationService).to receive(:call).and_return(true)
  end

  describe '.call' do
    context 'when valid' do
      let(:public_market) { create(:public_market, :completed, editor:) }

      subject { described_class.call(public_market:, siret:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates a persisted market application' do
        result = subject
        expect(result.market_application).to be_persisted
        expect(result.market_application.public_market).to eq(public_market)
        expect(result.market_application.siret).to eq(siret)
        expect(result.market_application.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      end
    end

    context 'when SIRET is missing' do
      let(:public_market) { create(:public_market, :completed, editor:) }

      subject { described_class.call(public_market:, siret: nil) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has presence validation error' do
        expect(subject.errors[:siret]).to be_present
      end
    end

    context 'when SIRET validation fails' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let(:invalid_siret) { '12345678901234' }

      before do
        allow(SiretValidationService).to receive(:call).with(public_market.siret).and_return(true)
        allow(SiretValidationService).to receive(:call).with(invalid_siret).and_return(false)
      end

      subject { described_class.call(public_market:, siret: invalid_siret) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has validation errors' do
        expect(subject.errors[:siret]).to be_present
      end
    end
  end
end
