# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationCreationService, type: :service do
  let(:editor) { create(:editor) }
  let(:siret) { '73282932000074' }

  describe '#perform' do
    context 'when valid' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let(:service) { described_class.new(public_market:, siret:).perform }

      before do
        allow(SiretValidationService).to receive(:call).and_return(true)
      end

      it 'returns success' do
        expect(service.success?).to be true
        expect(service.failure?).to be false
      end

      it 'has no errors' do
        expect(service.errors).to be_blank
      end

      it 'creates a market application successfully' do
        expect(service.result).to be_persisted
        expect(service.result.public_market).to eq(public_market)
        expect(service.result.siret).to eq(siret)
        expect(service.result.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      end
    end

    context 'when SIRET is missing' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let(:service) { described_class.new(public_market:, siret: nil).perform }

      before do
        allow(SiretValidationService).to receive(:call).and_return(true)
      end

      it 'returns failure' do
        expect(service.success?).to be false
        expect(service.failure?).to be true
      end

      it 'has presence validation error' do
        expect(service.errors[:siret]).to be_present
      end

      it 'has no result' do
        expect(service.result).to be_nil
      end
    end

    context 'when SIRET validation fails' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let(:invalid_siret) { '12345678901234' }
      let(:service) { described_class.new(public_market:, siret: invalid_siret).perform }

      before do
        allow(SiretValidationService).to receive(:call).with(public_market.siret).and_return(true)
        allow(SiretValidationService).to receive(:call).with(invalid_siret).and_return(false)
      end

      it 'returns failure' do
        expect(service.success?).to be false
        expect(service.failure?).to be true
      end

      it 'has validation errors' do
        expect(service.errors[:siret]).to be_present
      end

      it 'has no result' do
        expect(service.result).to be_nil
      end
    end
  end
end
