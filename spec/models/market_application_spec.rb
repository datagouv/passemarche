# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplication, type: :model do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor: editor) }

  before do
    allow(SiretValidationService).to receive(:call).and_return(true)
  end

  describe 'business validations' do
    it 'calls SiretValidationService for SIRET validation' do
      allow(SiretValidationService).to receive(:call).and_return(false)

      application = build(:market_application, public_market: public_market, siret: '12345678901234')

      expect(application).not_to be_valid
      expect(application.errors[:siret]).to include('Le numéro de SIRET saisi est invalide ou non reconnu, veuillez vérifier votre saisie.')
      expect(SiretValidationService).to have_received(:call).with('12345678901234')
    end

    it 'requires public market to be completed' do
      incomplete_market = create(:public_market, editor: editor, sync_status: :sync_pending)
      application = build(:market_application, public_market: incomplete_market, siret: '12345678901234')

      expect(application).not_to be_valid
      expect(application.errors[:public_market]).to include('must be completed')
    end
  end

  describe 'identifier generation' do
    it 'generates identifier on creation' do
      application = build(:market_application, public_market: public_market, siret: '12345678901234', identifier: nil)

      expect(application.identifier).to be_nil
      application.valid?
      expect(application.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
    end

    it 'does not override existing identifier' do
      existing_identifier = 'CUSTOM-ID'
      application = build(:market_application, public_market: public_market, siret: '12345678901234', identifier: existing_identifier)

      application.save!
      expect(application.identifier).to eq(existing_identifier)
    end
  end
end
