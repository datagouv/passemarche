# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::PresentationIntervenants, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :presentation_intervenants) }

  subject(:response) do
    described_class.new(
      market_application:,
      market_attribute:,
      value:
    )
  end

  describe 'associations' do
    let(:value) { {} }

    it { is_expected.to belong_to(:market_application) }
    it { is_expected.to belong_to(:market_attribute) }
  end

  describe 'includes' do
    let(:value) { {} }

    it 'includes FileAttachable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::FileAttachable)
    end

    it 'includes JsonValidatable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::JsonValidatable)
    end
  end

  describe 'JSON schema validation' do
    context 'with empty value' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end

    context 'with empty hash' do
      let(:value) { {} }

      it { is_expected.to be_valid }
    end

    context 'with valid persons data' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => {
              'nom' => 'Dupont',
              'prenoms' => 'Jean',
              'titres' => 'Ingénieur',
              'cv_attachment_id' => '123'
            },
            '1738234567891' => {
              'nom' => 'Martin',
              'prenoms' => 'Marie',
              'titres' => 'Architecte',
              'cv_attachment_id' => '456'
            }
          }
        }
      end

      it { is_expected.to be_valid }
    end

    context 'with invalid persons type' do
      let(:value) do
        {
          'items' => 'invalid string'
        }
      end

      it { is_expected.to be_invalid }

      it 'adds validation error' do
        response.valid?
        expect(response.errors[:value]).to include('persons must be a hash')
      end
    end

    context 'with person missing nom' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => {
              'prenoms' => 'Jean',
              'titres' => 'Ingénieur'
            }
          }
        }
      end

      context 'when market attribute is required' do
        before { allow(market_attribute).to receive(:required?).and_return(true) }

        it { is_expected.to be_invalid }

        it 'adds validation error' do
          response.valid?
          expect(response.errors[:value]).to include('Person 1: nom is required when person data is provided')
        end
      end

      context 'when market attribute is not required' do
        before { allow(market_attribute).to receive(:required?).and_return(false) }

        it { is_expected.to be_valid }
      end
    end

    context 'with empty person entry' do
      let(:value) do
        {
          'items' => { '1738234567890' => {} }
        }
      end

      it { is_expected.to be_valid }
    end
  end

  describe '#persons' do
    context 'when value is nil' do
      let(:value) { nil }

      it 'returns empty hash' do
        expect(response.persons).to eq({})
      end
    end

    context 'when persons exists' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => { 'nom' => 'Dupont', 'prenoms' => 'Jean' }
          }
        }
      end

      it 'returns persons hash' do
        expect(response.persons).to eq({ '1738234567890' => { 'nom' => 'Dupont', 'prenoms' => 'Jean' } })
      end
    end
  end

  describe '#persons=' do
    let(:value) { nil }

    it 'sets persons hash in value' do
      persons_data = { '1738234567890' => { 'nom' => 'Dupont', 'prenoms' => 'Jean' } }
      response.persons = persons_data
      expect(response.value['items']).to eq(persons_data)
    end

    it 'handles non-hash input' do
      response.persons = 'invalid'
      expect(response.value['items']).to eq({})
    end
  end

  describe 'person field management via assign_attributes' do
    let(:value) { nil }
    let(:timestamp1) { '1738234567890' }
    let(:timestamp2) { '1738234567891' }

    describe 'reading person fields' do
      context 'when no persons exist' do
        it 'returns nil' do
          expect(response.get_item_field(timestamp1, 'nom')).to be_nil
        end
      end

      context 'when person exists but no nom' do
        before { response.persons = { timestamp1 => {} } }

        it 'returns nil' do
          expect(response.get_item_field(timestamp1, 'nom')).to be_nil
        end
      end

      context 'when person has nom' do
        before { response.persons = { timestamp1 => { 'nom' => 'Dupont' } } }

        it 'returns the nom' do
          expect(response.get_item_field(timestamp1, 'nom')).to eq('Dupont')
        end
      end
    end

    describe 'writing person fields via assign_attributes' do
      it 'creates person entry and sets nom' do
        response.assign_attributes("person_#{timestamp1}_nom" => 'Dupont')
        expect(response.persons).to eq({ timestamp1 => { 'nom' => 'Dupont' } })
      end

      it 'updates existing person nom' do
        response.persons = { timestamp1 => { 'nom' => 'Martin' } }
        response.assign_attributes("person_#{timestamp1}_nom" => 'Dupont')
        expect(response.persons).to eq({ timestamp1 => { 'nom' => 'Dupont' } })
      end

      it 'handles nil value by setting to nil' do
        response.assign_attributes("person_#{timestamp1}_nom" => 'Dupont')
        response.assign_attributes("person_#{timestamp1}_nom" => nil)
        expect(response.persons[timestamp1]['nom']).to be_nil
      end

      it 'handles empty string by setting to nil' do
        response.assign_attributes("person_#{timestamp1}_nom" => 'Dupont')
        response.assign_attributes("person_#{timestamp1}_nom" => '')
        expect(response.persons[timestamp1]['nom']).to be_nil
      end
    end

    describe 'multiple person support' do
      let(:timestamp3) { '1738234567892' }

      it 'supports setting multiple persons via assign_attributes' do
        response.assign_attributes(
          "person_#{timestamp1}_nom" => 'Dupont',
          "person_#{timestamp2}_nom" => 'Martin',
          "person_#{timestamp3}_nom" => 'Durand'
        )

        expect(response.persons).to eq({
          timestamp1 => { 'nom' => 'Dupont' },
          timestamp2 => { 'nom' => 'Martin' },
          timestamp3 => { 'nom' => 'Durand' }
        })
      end

      it 'creates independent entries with no gaps' do
        response.assign_attributes("person_#{timestamp3}_nom" => 'Durand')

        expect(response.persons).to eq({
          timestamp3 => { 'nom' => 'Durand' }
        })
      end
    end
  end

  describe 'CV attachment handling' do
    let(:value) { nil }
    let(:timestamp1) { '1738234567890' }
    let(:timestamp2) { '1738234567891' }

    it 'attaches CV file to documents when uploaded via assign_attributes' do
      file = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes(
        "person_#{timestamp1}_nom" => 'Dupont',
        "person_#{timestamp1}_cv_attachment_id" => file
      )

      expect(response.documents).to be_attached
      expect(response.persons[timestamp1]['cv_attachment_id']).to eq('attached')
    end

    it 'stores "attached" marker in JSON when file uploaded' do
      file = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes("person_#{timestamp1}_cv_attachment_id" => file)
      response.save!

      marker = response.persons[timestamp1]['cv_attachment_id']
      expect(marker).to eq('attached')
    end

    it 'retrieves CV attachment for a person' do
      file = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes("person_#{timestamp1}_cv_attachment_id" => file)
      response.save!

      cv = response.person_cv_attachment(timestamp1)
      expect(cv).to be_present
      expect(cv.filename.to_s).to eq('test.pdf')
    end

    it 'returns nil when no CV attached for person' do
      response.assign_attributes("person_#{timestamp1}_nom" => 'Dupont')
      response.save!

      cv = response.person_cv_attachment(timestamp1)
      expect(cv).to be_nil
    end

    it 'handles multiple CV attachments for different persons' do
      file1 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')
      file2 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes(
        "person_#{timestamp1}_cv_attachment_id" => file1,
        "person_#{timestamp2}_cv_attachment_id" => file2
      )
      response.save!

      cv1 = response.person_cv_attachment(timestamp1)
      cv2 = response.person_cv_attachment(timestamp2)

      expect(cv1).to be_present
      expect(cv2).to be_present
      expect(cv1.signed_id).not_to eq(cv2.signed_id)
    end

    it 'auto-deletes old CV when uploading a new one for the same person' do
      file1 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')
      file2 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      # Upload first CV
      response.assign_attributes("person_#{timestamp1}_cv_attachment_id" => file1)
      response.save!

      first_cv = response.person_cv_attachment(timestamp1)
      first_cv_id = first_cv.signed_id
      first_cv_filename = first_cv.filename.to_s
      expect(response.documents.count).to eq(1)

      # Upload second CV for same person
      response.assign_attributes("person_#{timestamp1}_cv_attachment_id" => file2)
      response.save!

      # Should only have one CV now (old one purged)
      expect(response.documents.count).to eq(1)

      # Should retrieve the new CV (different from old one)
      current_cv = response.person_cv_attachment(timestamp1)
      expect(current_cv.signed_id).not_to eq(first_cv_id)
      expect(current_cv.filename.to_s).to eq(first_cv_filename)

      # Old CV attachment should not exist in documents collection
      expect(response.documents.map(&:signed_id)).not_to include(first_cv_id)
    end
  end
end
