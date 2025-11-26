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
      allow(SiretValidationService).to receive(:call).with(public_market.siret).and_return(true)
      allow(SiretValidationService).to receive(:call).with('12345678901234').and_return(false)

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

  describe 'subject_to_prohibition' do
    it 'accepts true' do
      application = build(:market_application, :subject_to_prohibition, public_market:)
      expect(application).to be_valid
    end

    it 'accepts false' do
      application = build(:market_application, :not_subject_to_prohibition, public_market:)
      expect(application).to be_valid
    end

    it 'accepts nil (not answered)' do
      application = build(:market_application, :prohibition_not_answered, public_market:)
      expect(application).to be_valid
    end

    it 'handles Rails boolean type casting' do
      application = build(:market_application, public_market:, subject_to_prohibition: 1)
      expect(application.subject_to_prohibition).to be true

      application = build(:market_application, public_market:, subject_to_prohibition: 0)
      expect(application.subject_to_prohibition).to be false

      application = build(:market_application, public_market:, subject_to_prohibition: '')
      expect(application.subject_to_prohibition).to be_nil
    end
  end

  describe '#prohibition_declared?' do
    it 'returns true when subject_to_prohibition is true' do
      application = build(:market_application, :subject_to_prohibition, public_market:)
      expect(application.prohibition_declared?).to be true
    end

    it 'returns false when subject_to_prohibition is false' do
      application = build(:market_application, :not_subject_to_prohibition, public_market:)
      expect(application.prohibition_declared?).to be false
    end

    it 'returns false when subject_to_prohibition is nil' do
      application = build(:market_application, :prohibition_not_answered, public_market:)
      expect(application.prohibition_declared?).to be false
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
            '0' => {
              'id' => response.id.to_s,
              'market_attribute_id' => market_attribute.id.to_s,
              "person_#{t1}_nom" => 'Dupont Updated',
              "person_#{t3}_nom" => 'Durand Updated'
            }
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

  describe 'context-aware validation' do
    let(:public_market) do
      create(:public_market, :completed, editor:).tap do |market|
        # Create attributes for two different steps
        create(:market_attribute, :text_input, public_markets: [market],
          subcategory_key: 'step_one',
          required: true)
        create(:market_attribute, :text_input, public_markets: [market],
          subcategory_key: 'step_two',
          required: true)
      end
    end

    let(:application) { create(:market_application, public_market:, siret: '12345678901234') }

    let(:step_one_attribute) { public_market.market_attributes.find_by(subcategory_key: 'step_one') }
    let(:step_two_attribute) { public_market.market_attributes.find_by(subcategory_key: 'step_two') }

    before do
      # Create invalid responses for both steps (bypass validation during creation)
      # Use text exceeding max length to trigger validation error
      response_one = application.market_attribute_responses.build(
        market_attribute: step_one_attribute,
        type: 'TextInput',
        value: { 'text' => 'a' * 10_001 }, # Exceeds max length, will fail validation
        source: :manual
      )
      response_one.save(validate: false)

      response_two = application.market_attribute_responses.build(
        market_attribute: step_two_attribute,
        type: 'TextInput',
        value: { 'text' => 'a' * 10_001 }, # Exceeds max length, will fail validation
        source: :manual
      )
      response_two.save(validate: false)

      # Reload to ensure associations are fresh
      application.reload
    end

    it 'sets current_validation_step when validating with context' do
      expect(application.current_validation_step).to be_nil

      application.valid?(:step_one)

      expect(application.current_validation_step).to eq(:step_one)
    end

    it 'only validates responses for the current step' do
      # When validating step_one, only step_one response should cause errors
      expect(application.valid?(:step_one)).to be false
      expect(application.errors[:siret]).to be_empty
      expect(application.errors.messages.keys.map(&:to_s)).to include('market_attribute_responses.text')
    end

    it 'does not validate responses from other steps' do
      # Clear errors and validate step_one with valid data
      step_one_response = application.market_attribute_responses.find_by(market_attribute: step_one_attribute)
      step_one_response.update_column(:value, { 'text' => 'valid text' })

      # Now step_one validation should pass even though step_two response is invalid
      expect(application.valid?(:step_one)).to be true
    end

    it 'skips validation for responses not in the current step' do
      step_two_response = application.market_attribute_responses.find_by(market_attribute: step_two_attribute)

      # When validating step_one, step_two response should not be validated
      application.valid?(:step_one)

      expect(step_two_response.should_validate_for_current_step?).to be false
    end

    it 'validates responses in the current step' do
      step_one_response = application.market_attribute_responses.find_by(market_attribute: step_one_attribute)

      application.valid?(:step_one)

      expect(step_one_response.should_validate_for_current_step?).to be true
    end

    it 'matches responses by subcategory_key not category_key' do # rubocop:disable Metrics/BlockLength
      # Create two attributes with the same category but different subcategories
      same_category_attr1 = create(:market_attribute, :text_input,
        public_markets: [public_market],
        category_key: 'identite', # Same category
        subcategory_key: 'subcategory_a', # Different subcategory
        required: true)

      same_category_attr2 = create(:market_attribute, :text_input,
        public_markets: [public_market],
        category_key: 'identite', # Same category
        subcategory_key: 'subcategory_b', # Different subcategory
        required: true)

      # Create responses for both
      response_a = application.market_attribute_responses.build(
        market_attribute: same_category_attr1,
        type: 'TextInput',
        value: {},
        source: :manual
      )
      response_a.save(validate: false)

      response_b = application.market_attribute_responses.build(
        market_attribute: same_category_attr2,
        type: 'TextInput',
        value: {},
        source: :manual
      )
      response_b.save(validate: false)

      application.reload

      # Validate only subcategory_a
      application.valid?(:subcategory_a)

      # Response A should be validated (belongs to subcategory_a)
      expect(response_a.should_validate_for_current_step?).to be true

      # Response B should NOT be validated (belongs to subcategory_b, even though same category)
      expect(response_b.should_validate_for_current_step?).to be false
    end
  end
end
