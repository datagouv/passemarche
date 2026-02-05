# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CheckboxFieldBehavior, type: :model do
  let(:checkbox_response) { build(:market_attribute_response_checkbox_with_document) }

  describe '#checked=' do
    context 'with boolean values' do
      it 'stores true in value hash' do
        checkbox_response.checked = true
        expect(checkbox_response.value['checked']).to be true
      end

      it 'stores false in value hash' do
        checkbox_response.checked = false
        expect(checkbox_response.value['checked']).to be false
      end
    end

    context 'with string values' do
      it 'casts "true" to true' do
        checkbox_response.checked = 'true'
        expect(checkbox_response.value['checked']).to be true
      end

      it 'casts "false" to false' do
        checkbox_response.checked = 'false'
        expect(checkbox_response.value['checked']).to be false
      end

      it 'casts "1" to true' do
        checkbox_response.checked = '1'
        expect(checkbox_response.value['checked']).to be true
      end

      it 'casts "0" to false' do
        checkbox_response.checked = '0'
        expect(checkbox_response.value['checked']).to be false
      end
    end

    context 'with nil value' do
      it 'removes checked key from value hash' do
        checkbox_response.value = { 'checked' => true, 'other' => 'data' }
        checkbox_response.checked = nil
        expect(checkbox_response.value).not_to have_key('checked')
        expect(checkbox_response.value['other']).to eq('data')
      end
    end

    context 'when value is nil' do
      it 'initializes value hash' do
        checkbox_response.value = nil
        checkbox_response.checked = true
        expect(checkbox_response.value).to eq({ 'checked' => true })
      end
    end
  end

  describe '#checked' do
    context 'when value is nil' do
      it 'returns nil' do
        checkbox_response.value = nil
        expect(checkbox_response.checked).to be_nil
      end
    end

    context 'when checked key is not present' do
      it 'returns nil' do
        checkbox_response.value = { 'other' => 'data' }
        expect(checkbox_response.checked).to be_nil
      end
    end

    context 'when checked is true' do
      it 'returns true' do
        checkbox_response.value = { 'checked' => true }
        expect(checkbox_response.checked).to be true
      end
    end

    context 'when checked is false' do
      it 'returns false' do
        checkbox_response.value = { 'checked' => false }
        expect(checkbox_response.checked).to be false
      end
    end
  end

  describe '#checked?' do
    it 'returns true when checked is true' do
      checkbox_response.value = { 'checked' => true }
      expect(checkbox_response.checked?).to be true
    end

    it 'returns false when checked is false' do
      checkbox_response.value = { 'checked' => false }
      expect(checkbox_response.checked?).to be false
    end

    it 'returns nil when checked is not set' do
      checkbox_response.value = nil
      expect(checkbox_response.checked?).to be_nil
    end
  end

  describe 'validation' do
    it 'is valid when checked is true' do
      checkbox_response.checked = true
      checkbox_response.valid?
      expect(checkbox_response.errors[:checked]).to be_empty
    end

    it 'is valid when checked is false' do
      checkbox_response.checked = false
      checkbox_response.valid?
      expect(checkbox_response.errors[:checked]).to be_empty
    end

    it 'is invalid when checked is nil' do
      checkbox_response.value = {}
      checkbox_response.valid?
      expect(checkbox_response.errors[:checked]).to be_present
    end

    context 'with invalid raw value' do
      it 'adds error when checked is not a boolean' do
        checkbox_response.value = { 'checked' => 'invalid_string' }
        checkbox_response.valid?
        expect(checkbox_response.errors[:checked]).to be_present
      end

      it 'adds error when checked is a number' do
        checkbox_response.value = { 'checked' => 42 }
        checkbox_response.valid?
        expect(checkbox_response.errors[:checked]).to be_present
      end
    end
  end

  describe 'boolean casting via ActiveModel::Type::Boolean' do
    it 'casts empty string to nil (removes from hash)' do
      checkbox_response.checked = ''
      expect(checkbox_response.value).not_to have_key('checked')
    end

    it 'casts "yes" to true (ActiveModel::Type::Boolean behavior)' do
      checkbox_response.checked = 'yes'
      expect(checkbox_response.value['checked']).to be true
    end

    it 'casts integer 1 to true' do
      checkbox_response.checked = 1
      expect(checkbox_response.value['checked']).to be true
    end

    it 'casts integer 0 to false' do
      checkbox_response.checked = 0
      expect(checkbox_response.value['checked']).to be false
    end
  end
end
