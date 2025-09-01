# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::TextInput, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'text_input') }
  let(:text_response) { build(:market_attribute_response_text_input, market_application:, market_attribute:) }

  describe 'constants' do
    it 'defines TEXT_MAX_LENGTH' do
      expect(MarketAttributeResponse::TextInput::TEXT_MAX_LENGTH).to eq(10_000)
    end
  end

  describe 'text accessor' do
    it 'returns nil when value is empty' do
      text_response.value = {}
      expect(text_response.text).to be_nil
    end

    it 'returns nil when value is nil' do
      text_response.value = nil
      expect(text_response.text).to be_nil
    end

    it 'returns the text value when present' do
      text_response.value = { 'text' => 'Hello World' }
      expect(text_response.text).to eq('Hello World')
    end

    it 'sets the text value' do
      text_response.text = 'New text'
      expect(text_response.value).to eq({ 'text' => 'New text' })
    end

    it 'preserves other values when setting text' do
      text_response.value = { 'other' => 'data' }
      text_response.text = 'New text'
      expect(text_response.value).to eq({ 'other' => 'data', 'text' => 'New text' })
    end
  end

  describe 'JSON schema validation' do
    context 'for new records' do
      it 'skips JSON schema validation' do
        text_response.value = { 'text' => 123 }
        text_response.valid?
        # Should not have JSON schema errors (validation skipped for new records)
        expect(text_response.errors[:value]).to be_empty
      end

      it 'allows nil value' do
        text_response.value = nil
        text_response.valid?
        expect(text_response.errors[:value]).to be_empty
      end
    end

    context 'for persisted records' do
      before do
        # Save the record to make it persisted
        text_response.save!(validate: false)
        text_response.reload
      end

      it 'validates correct structure' do
        text_response.value = { 'text' => 'Valid text' }
        expect(text_response).to be_valid
      end

      it 'validates text within length limit' do
        text_response.value = { 'text' => 'a' * 10_000 }
        expect(text_response).to be_valid
      end

      it 'validates empty string' do
        text_response.value = { 'text' => '' }
        expect(text_response).to be_valid
      end

      it 'rejects text exceeding length limit' do
        text_response.value = { 'text' => 'a' * 10_001 }
        expect(text_response).not_to be_valid
        expect(text_response.errors[:value]).to be_present
      end

      it 'rejects non-string values' do
        text_response.value = { 'text' => 123 }
        expect(text_response).not_to be_valid
        expect(text_response.errors[:value]).to be_present
      end

      it 'rejects missing text field' do
        text_response.value = {}
        expect(text_response).not_to be_valid
        expect(text_response.errors[:value]).to be_present
      end

      it 'rejects nil value' do
        text_response.value = nil
        expect(text_response).not_to be_valid
        expect(text_response.errors[:value]).to be_present
      end

      it 'rejects additional properties' do
        text_response.value = { 'text' => 'Valid text', 'extra' => 'field' }
        expect(text_response).not_to be_valid
        expect(text_response.errors[:value]).to be_present
      end
    end
  end
end
