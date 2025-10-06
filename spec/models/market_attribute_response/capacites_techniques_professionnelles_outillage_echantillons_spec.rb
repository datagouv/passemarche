# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) do
    create(:market_attribute, input_type: :capacites_techniques_professionnelles_outillage_echantillons)
  end

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

    it 'includes RepeatableField concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::RepeatableField)
    end

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

    context 'with valid echantillons data' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => {
              'description' => 'Échantillon de mobilier urbain',
              'fichiers' => 'attached'
            },
            '1738234567891' => {
              'description' => 'Prototype de signalétique',
              'fichiers' => 'attached'
            }
          }
        }
      end

      it { is_expected.to be_valid }
    end

    context 'with invalid echantillons type' do
      let(:value) do
        {
          'items' => 'invalid string'
        }
      end

      it { is_expected.to be_invalid }

      it 'adds validation error' do
        response.valid?
        expect(response.errors[:value]).to include('echantillons must be a hash')
      end
    end

    context 'with echantillon missing description' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => {
              'fichiers' => 'attached'
            }
          }
        }
      end

      context 'when market attribute is required' do
        before { allow(market_attribute).to receive(:required?).and_return(true) }

        it { is_expected.to be_invalid }

        it 'adds validation error' do
          response.valid?
          expect(response.errors[:value]).to include('Échantillon 1: description is required when echantillon data is provided')
        end
      end

      context 'when market attribute is not required' do
        before { allow(market_attribute).to receive(:required?).and_return(false) }

        it { is_expected.to be_valid }
      end
    end

    context 'with empty echantillon entry' do
      let(:value) do
        {
          'items' => { '1738234567890' => {} }
        }
      end

      it { is_expected.to be_valid }
    end
  end

  describe '#echantillons' do
    context 'when value is nil' do
      let(:value) { nil }

      it 'returns empty hash' do
        expect(response.echantillons).to eq({})
      end
    end

    context 'when echantillons exists' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => { 'description' => 'Échantillon test' }
          }
        }
      end

      it 'returns echantillons hash' do
        expect(response.echantillons).to eq({ '1738234567890' => { 'description' => 'Échantillon test' } })
      end
    end
  end

  describe '#echantillons=' do
    let(:value) { nil }

    it 'sets echantillons hash in value' do
      echantillons_data = { '1738234567890' => { 'description' => 'Test' } }
      response.echantillons = echantillons_data
      expect(response.value['items']).to eq(echantillons_data)
    end

    it 'handles non-hash input' do
      response.echantillons = 'invalid'
      expect(response.value['items']).to eq({})
    end
  end

  describe 'echantillon field management via assign_attributes' do
    let(:value) { nil }
    let(:timestamp1) { '1738234567890' }
    let(:timestamp2) { '1738234567891' }

    describe 'reading echantillon fields' do
      context 'when no echantillons exist' do
        it 'returns nil' do
          expect(response.get_item_field(timestamp1, 'description')).to be_nil
        end
      end

      context 'when echantillon exists but no description' do
        before { response.echantillons = { timestamp1 => {} } }

        it 'returns nil' do
          expect(response.get_item_field(timestamp1, 'description')).to be_nil
        end
      end

      context 'when echantillon has description' do
        before { response.echantillons = { timestamp1 => { 'description' => 'Test description' } } }

        it 'returns the description' do
          expect(response.get_item_field(timestamp1, 'description')).to eq('Test description')
        end
      end
    end

    describe 'writing echantillon fields via assign_attributes' do
      it 'creates echantillon entry and sets description' do
        response.assign_attributes("echantillon_#{timestamp1}_description" => 'Échantillon de test')
        expect(response.echantillons).to eq({ timestamp1 => { 'description' => 'Échantillon de test' } })
      end

      it 'updates existing echantillon description' do
        response.echantillons = { timestamp1 => { 'description' => 'Ancien' } }
        response.assign_attributes("echantillon_#{timestamp1}_description" => 'Nouveau')
        expect(response.echantillons).to eq({ timestamp1 => { 'description' => 'Nouveau' } })
      end

      it 'handles nil value by setting to nil' do
        response.assign_attributes("echantillon_#{timestamp1}_description" => 'Test')
        response.assign_attributes("echantillon_#{timestamp1}_description" => nil)
        expect(response.echantillons[timestamp1]['description']).to be_nil
      end

      it 'handles empty string by setting to nil' do
        response.assign_attributes("echantillon_#{timestamp1}_description" => 'Test')
        response.assign_attributes("echantillon_#{timestamp1}_description" => '')
        expect(response.echantillons[timestamp1]['description']).to be_nil
      end
    end

    describe 'multiple echantillon support' do
      let(:timestamp3) { '1738234567892' }

      it 'supports setting multiple echantillons via assign_attributes' do
        response.assign_attributes(
          "echantillon_#{timestamp1}_description" => 'Échantillon 1',
          "echantillon_#{timestamp2}_description" => 'Échantillon 2',
          "echantillon_#{timestamp3}_description" => 'Échantillon 3'
        )

        expect(response.echantillons).to eq({
          timestamp1 => { 'description' => 'Échantillon 1' },
          timestamp2 => { 'description' => 'Échantillon 2' },
          timestamp3 => { 'description' => 'Échantillon 3' }
        })
      end

      it 'creates independent entries with no gaps' do
        response.assign_attributes("echantillon_#{timestamp3}_description" => 'Échantillon 3')

        expect(response.echantillons).to eq({
          timestamp3 => { 'description' => 'Échantillon 3' }
        })
      end
    end
  end

  describe 'file attachment handling' do
    let(:value) { nil }
    let(:timestamp1) { '1738234567890' }
    let(:timestamp2) { '1738234567891' }

    it 'attaches multiple files to documents when uploaded via assign_attributes' do
      file1 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')
      file2 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes(
        "echantillon_#{timestamp1}_description" => 'Test',
        "echantillon_#{timestamp1}_fichiers" => [file1, file2]
      )

      expect(response.documents).to be_attached
      expect(response.echantillons[timestamp1]['fichiers']).to eq('attached')
    end

    it 'stores "attached" marker in JSON when files uploaded' do
      file = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes("echantillon_#{timestamp1}_fichiers" => [file])
      response.save!

      marker = response.echantillons[timestamp1]['fichiers']
      expect(marker).to eq('attached')
    end

    it 'retrieves multiple file attachments for an echantillon' do
      file1 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')
      file2 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes("echantillon_#{timestamp1}_fichiers" => [file1, file2])
      response.save!

      fichiers = response.echantillon_fichiers(timestamp1)
      expect(fichiers).to be_present
      expect(fichiers.count).to eq(2)
    end

    it 'returns empty array when no files attached for echantillon' do
      response.assign_attributes("echantillon_#{timestamp1}_description" => 'Test')
      response.save!

      fichiers = response.echantillon_fichiers(timestamp1)
      expect(fichiers).to eq([])
    end

    it 'handles multiple file attachments for different echantillons' do
      file1 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')
      file2 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      response.assign_attributes(
        "echantillon_#{timestamp1}_fichiers" => [file1],
        "echantillon_#{timestamp2}_fichiers" => [file2]
      )
      response.save!

      fichiers1 = response.echantillon_fichiers(timestamp1)
      fichiers2 = response.echantillon_fichiers(timestamp2)

      expect(fichiers1).to be_present
      expect(fichiers2).to be_present
      expect(fichiers1.first.signed_id).not_to eq(fichiers2.first.signed_id)
    end

    it 'keeps all files when uploading new ones (no cleanup)' do
      file1 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')
      file2 = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')

      # Upload first file
      response.assign_attributes("echantillon_#{timestamp1}_fichiers" => [file1])
      response.save!

      first_count = response.documents.count
      expect(first_count).to eq(1)

      # Upload second file for same echantillon
      response.assign_attributes("echantillon_#{timestamp1}_fichiers" => [file2])
      response.save!

      # Should have both files (no cleanup)
      expect(response.documents.count).to eq(2)
      expect(response.echantillon_fichiers(timestamp1).count).to eq(2)
    end
  end

  describe 'item_prefix' do
    let(:value) { nil }

    it 'uses "echantillon" as prefix' do
      expect(response.item_prefix).to eq('echantillon')
    end
  end

  describe 'specialized_document_fields' do
    let(:value) { nil }

    it 'includes fichiers' do
      expect(response.specialized_document_fields).to include('fichiers')
    end
  end

  describe 'cleanup_old_specialized_documents?' do
    let(:value) { nil }

    it 'returns false (keeps all files)' do
      expect(response.cleanup_old_specialized_documents?).to be false
    end
  end
end
