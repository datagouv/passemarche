# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplication, type: :model do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before do
    allow(SiretValidationService).to receive(:call).and_return(true)
  end

  describe 'business validations' do
    it 'calls SiretValidationService for SIRET validation' do
      allow(SiretValidationService).to receive(:call).and_return(false)

      application = build(:market_application, public_market:, siret: '12345678901234')

      expect(application).not_to be_valid
      expect(application.errors[:siret]).to include('Le numéro de SIRET saisi est invalide ou non reconnu, veuillez vérifier votre saisie.')
      expect(SiretValidationService).to have_received(:call).with('12345678901234')
    end

    it 'requires public market to be completed' do
      incomplete_market = create(:public_market, editor:, sync_status: :sync_pending)
      application = build(:market_application, public_market: incomplete_market, siret: '12345678901234')

      expect(application).not_to be_valid
      expect(application.errors[:public_market]).to include('must be completed')
    end
  end

  describe '#complete!' do
    let(:editor) { create(:editor) }
    let(:application) { create(:market_application, public_market:, siret: '12345678901234', identifier: nil) }

    it 'sets completed_at to current time' do
      freeze_time do
        application.complete!
        expect(application.completed_at).to eq(Time.zone.now)
      end
    end
  end

  describe 'sync status helpers' do
    let(:application) { create(:market_application, public_market:, siret: '12345678901234', identifier: nil) }

    describe '#sync_in_progress?' do
      it 'returns true for pending status' do
        application.sync_status = 'sync_pending'
        expect(application).to be_sync_in_progress
      end

      it 'returns true for processing status' do
        application.sync_status = 'sync_processing'
        expect(application).to be_sync_in_progress
      end

      it 'returns false for completed status' do
        application.sync_status = 'sync_completed'
        expect(application).not_to be_sync_in_progress
      end

      it 'returns false for failed status' do
        application.sync_status = 'sync_failed'
        expect(application).not_to be_sync_in_progress
      end
    end
  end

  describe 'identifier generation' do
    it 'generates identifier on creation' do
      application = build(:market_application, public_market:, siret: '12345678901234', identifier: nil)

      expect(application.identifier).to be_nil
      application.valid?
      expect(application.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
    end

    it 'does not override existing identifier' do
      existing_identifier = 'CUSTOM-ID'
      application = build(:market_application, public_market:, siret: '12345678901234', identifier: existing_identifier)

      application.save!
      expect(application.identifier).to eq(existing_identifier)
    end
  end

  describe 'ActiveStorage attachments' do
    let(:application) { create(:market_application, public_market: public_market, siret: '12345678901234') }

    describe '#attestation' do
      it 'has one attached attestation' do
        expect(application.attestation).to be_an(ActiveStorage::Attached::One)
      end

      it 'can attach an attestation file' do
        application.attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: 'test_attestation.pdf',
          content_type: 'application/pdf'
        )

        expect(application.attestation).to be_attached
        expect(application.attestation.filename.to_s).to eq('test_attestation.pdf')
        expect(application.attestation.content_type).to eq('application/pdf')
      end
    end

    describe '#documents_package' do
      it 'has one attached documents_package' do
        expect(application.documents_package).to be_an(ActiveStorage::Attached::One)
      end

      it 'can attach a documents package file' do
        application.documents_package.attach(
          io: StringIO.new('fake zip content'),
          filename: 'test_package.zip',
          content_type: 'application/zip'
        )

        expect(application.documents_package).to be_attached
        expect(application.documents_package.filename.to_s).to eq('test_package.zip')
        expect(application.documents_package.content_type).to eq('application/zip')
      end
    end
  end
end
