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
    let(:application) { create(:market_application, public_market:, siret: '12345678901234') }

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

  describe 'nested attributes for market_attribute_responses' do
    let(:application) { create(:market_application, public_market:, siret: '12345678901234') }
    let(:market_attribute) do
      create(:market_attribute,
        key: 'test_field',
        input_type: 'text_input',
        category_key: 'identite_entreprise',
        subcategory_key: 'identification',
        required: true)
    end

    before do
      public_market.market_attributes << market_attribute
    end

    describe '#market_attribute_responses_attributes=' do
      it 'creates new response when id is empty' do
        expect do
          application.update(
            market_attribute_responses_attributes: {
              '0' => {
                'id' => '',
                'market_attribute_id' => market_attribute.id.to_s,
                'type' => 'TextInput',
                'text' => 'Test value'
              }
            }
          )
        end.to change { application.market_attribute_responses.count }.by(1)

        response = application.market_attribute_responses.last
        expect(response.type).to eq('TextInput')
        expect(response.text).to eq('Test value')
      end

      it 'updates existing response when id is provided' do
        response = application.market_attribute_responses.create!(
          market_attribute:,
          type: 'TextInput',
          text: 'Original value'
        )

        application.update(
          market_attribute_responses_attributes: {
            '0' => {
              'id' => response.id.to_s,
              'market_attribute_id' => market_attribute.id.to_s,
              'type' => 'TextInput',
              'text' => 'Updated value'
            }
          }
        )

        expect(response.reload.text).to eq('Updated value')
      end

      it 'destroys response when _destroy is true' do
        response = application.market_attribute_responses.create!(
          market_attribute:,
          type: 'TextInput',
          text: 'Original value'
        )

        # Rails' accepts_nested_attributes_for with allow_destroy: true will destroy the record
        expect do
          application.update(
            market_attribute_responses_attributes: {
              '0' => {
                'id' => response.id.to_s,
                '_destroy' => '1'
              }
            }
          )
        end.to change { application.market_attribute_responses.count }.by(-1)

        # Response should be destroyed
        expect(MarketAttributeResponse.find_by(id: response.id)).to be_nil
      end
    end

    describe 'nested attributes with person fields' do
      let(:market_attribute) do
        MarketAttribute.find_or_create_by(
          key: 'presentation_intervenants'
        ) do |attr|
          attr.input_type = 'presentation_intervenants'
          attr.category_key = 'capacites_techniques_professionnelles'
          attr.subcategory_key = 'effectifs'
          attr.required = true
        end
      end

      it 'creates response with person data' do
        timestamp = '1738234567890'
        application.update(
          market_attribute_responses_attributes: {
            '0' => {
              'id' => '',
              'market_attribute_id' => market_attribute.id.to_s,
              'type' => 'PresentationIntervenants',
              "person_#{timestamp}_nom" => 'Dupont',
              "person_#{timestamp}_prenoms" => 'Jean',
              "person_#{timestamp}_titres" => 'Ingénieur'
            }
          }
        )

        response = application.market_attribute_responses.last
        expect(response.get_item_field(timestamp, 'nom')).to eq('Dupont')
        expect(response.get_item_field(timestamp, 'prenoms')).to eq('Jean')
        expect(response.get_item_field(timestamp, 'titres')).to eq('Ingénieur')
      end

      it 'handles multiple persons' do
        timestamp1 = '1738234567890'
        timestamp2 = '1738234567891'
        timestamp3 = '1738234567892'

        application.update(
          market_attribute_responses_attributes: {
            '0' => {
              'id' => '',
              'market_attribute_id' => market_attribute.id.to_s,
              'type' => 'PresentationIntervenants',
              "person_#{timestamp1}_nom" => 'Dupont',
              "person_#{timestamp2}_nom" => 'Martin',
              "person_#{timestamp3}_nom" => 'Durand'
            }
          }
        )

        response = application.market_attribute_responses.last
        expect(response.persons.length).to eq(3)
        expect(response.get_item_field(timestamp1, 'nom')).to eq('Dupont')
        expect(response.get_item_field(timestamp2, 'nom')).to eq('Martin')
        expect(response.get_item_field(timestamp3, 'nom')).to eq('Durand')
      end

      it 'does not clear unsubmitted person fields on update' do
        t1 = '1738234567890'
        t2 = '1738234567891'
        t3 = '1738234567892'

        response = application.market_attribute_responses.create!(
          market_attribute:,
          type: 'PresentationIntervenants'
        )

        # Create initial data with 3 persons
        response.assign_attributes("person_#{t1}_nom" => 'Dupont', "person_#{t2}_nom" => 'Martin',
          "person_#{t3}_nom" => 'Durand')
        response.save!

        # Update only t1 and t3 - t2 remains unchanged
        application.update(
          market_attribute_responses_attributes: {
            '0' => { 'id' => response.id.to_s, 'market_attribute_id' => market_attribute.id.to_s,
                     "person_#{t1}_nom" => 'Dupont Updated', "person_#{t3}_nom" => 'Durand Updated' }
          }
        )

        response.reload
        expect(response.get_item_field(t1, 'nom')).to eq('Dupont Updated')
        expect(response.get_item_field(t2, 'nom')).to eq('Martin')
        expect(response.get_item_field(t3, 'nom')).to eq('Durand Updated')
      end

      it 'handles person fields with different timestamps' do
        timestamp1 = '1738234567890'
        timestamp2 = '1738234567895' # Gap in timestamps

        application.update(
          market_attribute_responses_attributes: {
            '0' => {
              'id' => '',
              'market_attribute_id' => market_attribute.id.to_s,
              'type' => 'PresentationIntervenants',
              "person_#{timestamp1}_nom" => 'Dupont',
              "person_#{timestamp2}_nom" => 'Martin'
            }
          }
        )

        response = application.market_attribute_responses.last
        # With timestamp-based storage, timestamps can have any value
        expect(response.persons.length).to eq(2)
        expect(response.get_item_field(timestamp1, 'nom')).to eq('Dupont')
        expect(response.get_item_field(timestamp2, 'nom')).to eq('Martin')
      end
    end

    # NOTE: build_market_attribute_response was removed in favor of Rails' standard
    # accepts_nested_attributes_for implementation which automatically builds
    # the correct STI class based on the 'type' parameter
  end
end
