# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::Textarea, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'textarea') }
  let(:textarea_response) { build(:market_attribute_response_textarea, market_application:, market_attribute:) }

  describe 'constants' do
    it 'defines TEXT_MAX_LENGTH' do
      expect(MarketAttributeResponse::Textarea::TEXT_MAX_LENGTH).to eq(10_000)
    end
  end

  describe 'text accessor' do
    it 'returns nil when value is empty' do
      textarea_response.value = {}
      expect(textarea_response.text).to be_nil
    end

    it 'returns nil when value is nil' do
      textarea_response.value = nil
      expect(textarea_response.text).to be_nil
    end

    it 'returns the text value when present' do
      textarea_response.value = { 'text' => 'Hello World' }
      expect(textarea_response.text).to eq('Hello World')
    end

    it 'sets the text value' do
      textarea_response.text = 'New text'
      expect(textarea_response.value).to eq({ 'text' => 'New text' })
    end

    it 'preserves other values when setting text' do
      textarea_response.value = { 'other' => 'data' }
      textarea_response.text = 'New text'
      expect(textarea_response.value).to eq({ 'other' => 'data', 'text' => 'New text' })
    end
  end

  describe 'JSON schema validation' do
    context 'for new records' do
      it 'skips JSON schema validation' do
        textarea_response.value = { 'text' => 123 }
        textarea_response.valid?
        # Should not have JSON schema errors (validation skipped for new records)
        expect(textarea_response.errors[:value]).to be_empty
      end

      it 'allows nil value' do
        textarea_response.value = nil
        textarea_response.valid?
        expect(textarea_response.errors[:value]).to be_empty
      end
    end

    context 'for persisted records' do
      before do
        # Save the record to make it persisted
        textarea_response.save!(validate: false)
        textarea_response.reload
      end

      it 'validates correct structure' do
        textarea_response.value = { 'text' => 'Valid text' }
        expect(textarea_response).to be_valid
      end

      it 'validates text within length limit' do
        textarea_response.value = { 'text' => 'a' * 10_000 }
        expect(textarea_response).to be_valid
      end

      it 'allows empty string for manual fields' do
        textarea_response.value = { 'text' => '' }
        expect(textarea_response).to be_valid
      end

      it 'rejects text exceeding length limit' do
        textarea_response.value = { 'text' => 'a' * 10_001 }
        expect(textarea_response).not_to be_valid
        expect(textarea_response.errors[:text]).to be_present
      end

      it 'rejects non-string values' do
        textarea_response.value = { 'text' => 123 }
        expect(textarea_response).not_to be_valid
        expect(textarea_response.errors[:text]).to be_present
      end

      it 'allows missing text field' do
        textarea_response.value = {}
        expect(textarea_response).to be_valid
      end

      it 'allows nil value' do
        textarea_response.value = nil
        expect(textarea_response).to be_valid
      end

      it 'rejects additional properties' do
        textarea_response.value = { 'text' => 'Valid text', 'extra' => 'field' }
        expect(textarea_response).not_to be_valid
        expect(textarea_response.errors[:text]).to be_present
      end
    end
  end
end
