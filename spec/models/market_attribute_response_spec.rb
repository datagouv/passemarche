# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:market_application) }
    it { is_expected.to belong_to(:market_attribute) }
  end

  describe 'validations' do
    subject { build(:market_attribute_response) }

    before { allow(subject).to receive(:set_type_from_market_attribute) }

    it 'validates presence and inclusion of type' do
      expect(subject).to validate_presence_of(:type)
      expect(subject).to validate_inclusion_of(:type).in_array(%w[Checkbox TextInput FileUpload FileOrTextarea])
    end
  end

  describe 'automatic type setting' do
    it 'sets type from market_attribute input_type on create' do
      market_attribute = create(:market_attribute, input_type: 'text_input')
      response = build(:market_attribute_response, market_attribute:, type: nil)

      response.valid?
      expect(response.type).to eq('TextInput')
    end

    it 'does not override existing type' do
      market_attribute = create(:market_attribute, input_type: 'checkbox')
      response = build(:market_attribute_response, market_attribute:, type: 'TextInput')

      response.valid?
      expect(response.type).to eq('TextInput')
    end
  end

  describe 'STI class resolution' do
    it 'finds Checkbox class' do
      expect(MarketAttributeResponse.find_sti_class('Checkbox')).to eq(MarketAttributeResponse::Checkbox)
    end

    it 'finds TextInput class' do
      expect(MarketAttributeResponse.find_sti_class('TextInput')).to eq(MarketAttributeResponse::TextInput)
    end

    it 'finds FileUpload class' do
      expect(MarketAttributeResponse.find_sti_class('FileUpload')).to eq(MarketAttributeResponse::FileUpload)
    end

    it 'find FileOrTextarea class' do
      expect(MarketAttributeResponse.find_sti_class('FileOrTextarea')).to eq(MarketAttributeResponse::FileOrTextarea)
    end

    it 'finds CheckboxWithDocument class' do
      expect(
        MarketAttributeResponse.find_sti_class('CheckboxWithDocument')
      ).to eq(MarketAttributeResponse::CheckboxWithDocument)
    end
  end

  describe 'sti_name' do
    it 'returns demodulized class name for Checkbox' do
      expect(MarketAttributeResponse::Checkbox.sti_name).to eq('Checkbox')
    end

    it 'returns demodulized class name for TextInput' do
      expect(MarketAttributeResponse::TextInput.sti_name).to eq('TextInput')
    end

    it 'returns demodulized class name for FileUpload' do
      expect(MarketAttributeResponse::FileUpload.sti_name).to eq('FileUpload')
    end
  end

  describe 'source enum' do
    let(:response) { build(:market_attribute_response_text_input) }

    it 'has manual as default value' do
      expect(response.source).to eq('manual')
    end

    it 'can be set to auto' do
      response.source = :auto
      expect(response).to be_auto
    end

    it 'can be set to manual_after_api_failure' do
      response.source = :manual_after_api_failure
      expect(response).to be_manual_after_api_failure
    end
  end

  describe '::FILE_ATTACHABLE_TYPES' do
    it 'includes all file-attachable types' do
      expect(MarketAttributeResponse::FILE_ATTACHABLE_TYPES).to contain_exactly(
        'FileUpload',
        'InlineFileUpload',
        'CheckboxWithDocument',
        'RadioWithFileAndText',
        'RadioWithJustificationRequired',
        'RadioWithJustificationOptional',
        'FileOrTextarea',
        'PresentationIntervenants',
        'RealisationsLivraisons',
        'CapacitesTechniquesProfessionnellesOutillageEchantillons'
      )
    end

    it 'is frozen' do
      expect(MarketAttributeResponse::FILE_ATTACHABLE_TYPES).to be_frozen
    end
  end

  describe '.with_file_attachments' do
    it 'generates correct SQL query' do
      scope = MarketAttributeResponse.with_file_attachments
      expect(scope.to_sql).to include(
        "WHERE \"market_attribute_responses\".\"type\" IN ('FileUpload', 'InlineFileUpload', 'CheckboxWithDocument', 'RadioWithFileAndText', 'RadioWithJustificationRequired', 'RadioWithJustificationOptional', 'FileOrTextarea', 'PresentationIntervenants', 'RealisationsLivraisons', 'CapacitesTechniquesProfessionnellesOutillageEchantillons')"
      )
    end

    it 'can be chained with other scopes' do
      market_application = create(:market_application)
      scope = market_application.market_attribute_responses.with_file_attachments
      expect(scope).to be_a(ActiveRecord::Relation)
    end
  end
end
