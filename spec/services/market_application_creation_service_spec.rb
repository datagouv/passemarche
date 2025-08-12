# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationCreationService, type: :service do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor: editor) }
  let(:siret) { '12345678901234' }

  before do
    allow(SiretValidationService).to receive(:call).and_return(true)
  end

  describe '#call' do
    it 'creates a market application successfully' do
      result = described_class.call(public_market: public_market, siret: siret)

      expect(result).to be_persisted
      expect(result.public_market).to eq(public_market)
      expect(result.siret).to eq(siret)
      expect(result.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
    end

    it 'raises error when validation fails' do
      allow(SiretValidationService).to receive(:call).and_return(false)

      expect {
        described_class.call(public_market: public_market, siret: siret)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
