# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse, type: :model do
  describe 'associations' do
    it { should belong_to(:market_application) }
    it { should belong_to(:market_attribute) }
  end

  describe 'validations' do
    subject { build(:market_attribute_response) }

    it { should validate_presence_of(:type) }
    it { should validate_inclusion_of(:type).in_array(%w[Checkbox TextInput FileUpload FileOrTextarea]) }
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
end
