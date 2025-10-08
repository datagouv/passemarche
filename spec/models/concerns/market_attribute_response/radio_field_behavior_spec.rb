# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::RadioFieldBehavior, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :radio_with_file_and_text) }

  subject(:response) do
    MarketAttributeResponse::RadioWithFileAndText.new(
      market_application:,
      market_attribute:,
      value:
    )
  end

  describe 'default value' do
    context 'when creating a new record' do
      let(:value) { nil }

      it 'sets radio_choice to "no" by default' do
        expect(response.radio_choice).to eq('no')
      end

      it 'returns true for radio_no?' do
        expect(response.radio_no?).to be true
      end

      it 'returns false for radio_yes?' do
        expect(response.radio_yes?).to be false
      end
    end

    context 'when loading an existing record' do
      let(:value) { { 'radio_choice' => 'yes' } }

      it 'preserves the existing value' do
        response.save!
        reloaded = MarketAttributeResponse::RadioWithFileAndText.find(response.id)
        expect(reloaded.radio_choice).to eq('yes')
      end
    end
  end

  describe 'radio_choice setter' do
    let(:value) { nil }

    it 'accepts "yes" value' do
      response.radio_choice = 'yes'
      expect(response.radio_choice).to eq('yes')
    end

    it 'accepts "no" value' do
      response.radio_choice = 'no'
      expect(response.radio_choice).to eq('no')
    end

    it 'normalizes "Yes" to "yes"' do
      response.radio_choice = 'Yes'
      expect(response.radio_choice).to eq('yes')
    end

    it 'normalizes "YES" to "yes"' do
      response.radio_choice = 'YES'
      expect(response.radio_choice).to eq('yes')
    end

    it 'normalizes "No" to "no"' do
      response.radio_choice = 'No'
      expect(response.radio_choice).to eq('no')
    end

    it 'normalizes "NO" to "no"' do
      response.radio_choice = 'NO'
      expect(response.radio_choice).to eq('no')
    end

    it 'strips whitespace' do
      response.radio_choice = '  yes  '
      expect(response.radio_choice).to eq('yes')
    end

    it 'removes radio_choice from value when set to nil' do
      response.radio_choice = 'yes'
      response.radio_choice = nil
      expect(response.value).not_to have_key('radio_choice')
    end

    it 'removes radio_choice from value when set to empty string' do
      response.radio_choice = 'yes'
      response.radio_choice = ''
      expect(response.value).not_to have_key('radio_choice')
    end
  end

  describe 'radio_choice getter' do
    context 'when value is nil' do
      let(:value) { nil }

      it 'returns nil' do
        response.radio_choice = nil
        expect(response.radio_choice).to be_nil
      end
    end

    context 'when value has radio_choice key' do
      let(:value) { { 'radio_choice' => 'yes' } }

      it 'returns the stored value' do
        expect(response.radio_choice).to eq('yes')
      end
    end
  end

  describe 'radio_yes?' do
    let(:value) { nil }

    it 'returns true when radio_choice is "yes"' do
      response.radio_choice = 'yes'
      expect(response.radio_yes?).to be true
    end

    it 'returns false when radio_choice is "no"' do
      response.radio_choice = 'no'
      expect(response.radio_yes?).to be false
    end

    it 'returns false when radio_choice is nil' do
      response.radio_choice = nil
      expect(response.radio_yes?).to be false
    end
  end

  describe 'radio_no?' do
    let(:value) { nil }

    it 'returns true when radio_choice is "no"' do
      response.radio_choice = 'no'
      expect(response.radio_no?).to be true
    end

    it 'returns false when radio_choice is "yes"' do
      response.radio_choice = 'yes'
      expect(response.radio_no?).to be false
    end

    it 'returns false when radio_choice is nil' do
      response.radio_choice = nil
      expect(response.radio_no?).to be false
    end
  end

  describe 'validations' do
    let(:value) { nil }

    it 'is valid with "yes"' do
      response.radio_choice = 'yes'
      expect(response).to be_valid
    end

    it 'is valid with "no"' do
      response.radio_choice = 'no'
      expect(response).to be_valid
    end

    it 'is valid with nil' do
      response.radio_choice = nil
      expect(response).to be_valid
    end

    it 'is invalid with "maybe"' do
      response.radio_choice = 'maybe'
      expect(response).to be_invalid
      expect(response.errors[:radio_choice]).to be_present
    end

    it 'is invalid with arbitrary string' do
      response.radio_choice = 'invalid_value'
      expect(response).to be_invalid
      expect(response.errors[:radio_choice]).to be_present
    end
  end

  describe 'type validation' do
    context 'when radio_choice is not a string' do
      let(:value) { { 'radio_choice' => 123 } }

      it 'is invalid' do
        expect(response).to be_invalid
        expect(response.errors[:radio_choice]).to be_present
      end
    end

    context 'when radio_choice is a boolean' do
      let(:value) { { 'radio_choice' => true } }

      it 'is invalid' do
        expect(response).to be_invalid
        expect(response.errors[:radio_choice]).to be_present
      end
    end

    context 'when radio_choice is a valid string' do
      let(:value) { { 'radio_choice' => 'yes' } }

      it 'is valid' do
        expect(response).to be_valid
      end
    end
  end
end
