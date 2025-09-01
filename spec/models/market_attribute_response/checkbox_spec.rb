# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::Checkbox, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'checkbox') }
  let(:checkbox_response) { build(:market_attribute_response_checkbox, market_application:, market_attribute:) }

  describe 'checked accessor' do
    it 'returns nil when value is empty' do
      checkbox_response.value = {}
      expect(checkbox_response.checked).to be_nil
    end

    it 'returns nil when value is nil' do
      checkbox_response.value = nil
      expect(checkbox_response.checked).to be_nil
    end

    it 'returns the checked value when present' do
      checkbox_response.value = { 'checked' => true }
      expect(checkbox_response.checked).to eq(true)
    end

    it 'sets the checked value' do
      checkbox_response.checked = true
      expect(checkbox_response.value).to eq({ 'checked' => true })
    end

    it 'preserves other values when setting checked' do
      checkbox_response.value = { 'other' => 'data' }
      checkbox_response.checked = true
      expect(checkbox_response.value).to eq({ 'other' => 'data', 'checked' => true })
    end

    it 'type casts string values to boolean' do
      checkbox_response.checked = 'true'
      expect(checkbox_response.checked).to eq(true)

      checkbox_response.checked = 'false'
      expect(checkbox_response.checked).to eq(false)
    end
  end

  describe 'JSON schema validation' do
    context 'for new records' do
      it 'skips JSON schema validation' do
        checkbox_response.value = { 'checked' => 'invalid' }
        checkbox_response.valid?
        # Should not have JSON schema errors (validation skipped for new records)
        expect(checkbox_response.errors[:value]).to be_empty
      end

      it 'allows nil value' do
        checkbox_response.value = nil
        checkbox_response.valid?
        expect(checkbox_response.errors[:value]).to be_empty
      end
    end

    context 'for persisted records' do
      before do
        # Save the record to make it persisted
        checkbox_response.save!(validate: false)
        checkbox_response.reload
      end

      it 'validates correct structure with true' do
        checkbox_response.value = { 'checked' => true }
        expect(checkbox_response).to be_valid
      end

      it 'validates correct structure with false' do
        checkbox_response.value = { 'checked' => false }
        expect(checkbox_response).to be_valid
      end

      it 'rejects non-boolean values' do
        checkbox_response.value = { 'checked' => 'yes' }
        expect(checkbox_response).not_to be_valid
        expect(checkbox_response.errors[:checked]).to be_present
      end

      it 'rejects missing checked field' do
        checkbox_response.value = {}
        expect(checkbox_response).not_to be_valid
        expect(checkbox_response.errors[:checked]).to be_present
      end

      it 'rejects nil value' do
        checkbox_response.value = nil
        expect(checkbox_response).not_to be_valid
        expect(checkbox_response.errors[:checked]).to be_present
      end

      it 'rejects additional properties' do
        checkbox_response.value = { 'checked' => true, 'extra' => 'field' }
        expect(checkbox_response).not_to be_valid
        expect(checkbox_response.errors[:checked]).to be_present
      end
    end
  end
end
