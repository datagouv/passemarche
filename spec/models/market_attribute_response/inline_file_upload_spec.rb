require 'rails_helper'

RSpec.describe MarketAttributeResponse::InlineFileUpload, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'inline_file_upload') }
  let(:inline_file_upload) do
    MarketAttributeResponse::InlineFileUpload.new(
      market_application:,
      market_attribute:
    )
  end

  describe 'inheritance' do
    it 'inherits from FileUpload' do
      expect(described_class.superclass).to eq(MarketAttributeResponse::FileUpload)
    end

    it 'includes FileAttachable concern through parent' do
      expect(inline_file_upload).to respond_to(:documents)
    end
  end

  describe 'validation' do
    it 'allows no documents attached' do
      expect(inline_file_upload).to be_valid
    end
  end

  describe 'STI type' do
    it 'sets correct type' do
      inline_file_upload.save
      expect(inline_file_upload.type).to eq('InlineFileUpload')
    end
  end

  describe 'Qualiopi metadata accessors' do
    let(:market_attribute) do
      create(:market_attribute, input_type: 'inline_file_upload', api_name: 'carif_oref', api_key: 'qualiopi')
    end
    let(:qualiopi_value) do
      {
        'numero_de_declaration' => '11910843391',
        'actif' => true,
        'date_derniere_declaration' => '2021-01-30',
        'certification_qualiopi' => {
          'action_formation' => true,
          'bilan_competences' => true,
          'validation_acquis_experience' => false,
          'apprentissage' => true,
          'obtention_via_unite_legale' => true
        },
        'specialites' => [
          { 'code' => '313', 'libelle' => 'Finances, banque, assurances' },
          { 'code' => '326', 'libelle' => 'Informatique' }
        ]
      }
    end

    describe '#numero_de_declaration' do
      it 'returns numero_de_declaration from value hash' do
        inline_file_upload.value = qualiopi_value
        expect(inline_file_upload.numero_de_declaration).to eq('11910843391')
      end

      it 'returns nil when value is nil' do
        inline_file_upload.value = nil
        expect(inline_file_upload.numero_de_declaration).to be_nil
      end
    end

    describe '#certification_qualiopi' do
      it 'returns certification_qualiopi hash from value' do
        inline_file_upload.value = qualiopi_value
        expect(inline_file_upload.certification_qualiopi).to eq({
          'action_formation' => true,
          'bilan_competences' => true,
          'validation_acquis_experience' => false,
          'apprentissage' => true,
          'obtention_via_unite_legale' => true
        })
      end

      it 'returns nil when value is nil' do
        inline_file_upload.value = nil
        expect(inline_file_upload.certification_qualiopi).to be_nil
      end
    end

    describe '#specialites' do
      it 'returns specialites array from value hash' do
        inline_file_upload.value = qualiopi_value
        expect(inline_file_upload.specialites).to eq([
          { 'code' => '313', 'libelle' => 'Finances, banque, assurances' },
          { 'code' => '326', 'libelle' => 'Informatique' }
        ])
      end

      it 'returns empty array when value is nil' do
        inline_file_upload.value = nil
        expect(inline_file_upload.specialites).to eq([])
      end

      it 'returns empty array when specialites key is missing' do
        inline_file_upload.value = { 'numero_de_declaration' => '123' }
        expect(inline_file_upload.specialites).to eq([])
      end
    end

    describe 'certification flag helpers' do
      before { inline_file_upload.value = qualiopi_value }

      describe '#action_formation?' do
        it 'returns true when action_formation is true' do
          expect(inline_file_upload.action_formation?).to be true
        end

        it 'returns false when certification_qualiopi is nil' do
          inline_file_upload.value = nil
          expect(inline_file_upload.action_formation?).to be false
        end
      end

      describe '#bilan_competences?' do
        it 'returns true when bilan_competences is true' do
          expect(inline_file_upload.bilan_competences?).to be true
        end
      end

      describe '#validation_acquis_experience?' do
        it 'returns false when validation_acquis_experience is false' do
          expect(inline_file_upload.validation_acquis_experience?).to be false
        end
      end

      describe '#apprentissage?' do
        it 'returns true when apprentissage is true' do
          expect(inline_file_upload.apprentissage?).to be true
        end
      end

      describe '#obtention_via_unite_legale?' do
        it 'returns true when obtention_via_unite_legale is true' do
          expect(inline_file_upload.obtention_via_unite_legale?).to be true
        end
      end
    end

    describe '#qualiopi_metadata?' do
      it 'returns true when carif_oref/qualiopi with certification_qualiopi' do
        inline_file_upload.value = qualiopi_value
        expect(inline_file_upload.qualiopi_metadata?).to be true
      end

      it 'returns false when carif_oref/qualiopi without certification_qualiopi' do
        inline_file_upload.value = { 'numero_de_declaration' => '123' }
        expect(inline_file_upload.qualiopi_metadata?).to be false
      end

      it 'returns false when value is nil' do
        inline_file_upload.value = nil
        expect(inline_file_upload.qualiopi_metadata?).to be false
      end

      it 'returns false when not carif_oref api' do
        other_attribute = create(:market_attribute, input_type: 'inline_file_upload', api_name: 'other', api_key: 'qualiopi')
        other_upload = MarketAttributeResponse::InlineFileUpload.new(
          market_application:,
          market_attribute: other_attribute
        )
        other_upload.value = qualiopi_value
        expect(other_upload.qualiopi_metadata?).to be false
      end

      it 'returns false when wrong api_key' do
        france_comp_attribute = create(:market_attribute, input_type: 'inline_file_upload', api_name: 'carif_oref', api_key: 'france_competence')
        france_comp_upload = MarketAttributeResponse::InlineFileUpload.new(
          market_application:,
          market_attribute: france_comp_attribute
        )
        france_comp_upload.value = qualiopi_value
        expect(france_comp_upload.qualiopi_metadata?).to be false
      end
    end
  end
end
