require 'rails_helper'

RSpec.describe MarketAttributeResponse::PhoneInput, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'phone') }
  let(:phone_response) { described_class.new(market_application:, market_attribute:) }

  describe 'validations' do
    it 'accepts 0123456789' do
      phone_response.text = '0123456789'
      expect(phone_response).to be_valid
    end

    it 'accepts 01 23 45 67 89' do
      phone_response.text = '01 23 45 67 89'
      expect(phone_response).to be_valid
    end

    it 'accepts 01-23-45-67-89' do
      phone_response.text = '01-23-45-67-89'
      expect(phone_response).to be_valid
    end

    it 'accepts +33 1 23 45 67 89' do
      phone_response.text = '+33 1 23 45 67 89'
      expect(phone_response).to be_valid
    end

    it 'accepts international phone numbers' do
      phone_response.text = '+49 30 123456'
      expect(phone_response).to be_valid
    end

    it 'rejects when too short' do
      phone_response.text = '123456789'
      expect(phone_response).not_to be_valid
      expect(phone_response.errors[:text]).to be_present
    end

    it 'rejects when too long' do
      phone_response.text = '01234567890123456789'
      expect(phone_response).not_to be_valid
      expect(phone_response.errors[:text]).to be_present
    end

    it 'rejects when incomplete' do
      phone_response.text = '01 23 45 67'
      expect(phone_response).not_to be_valid
      expect(phone_response.errors[:text]).to be_present
    end

    it 'rejects when letters are present' do
      phone_response.text = '01 23 45 AB 89'
      expect(phone_response).not_to be_valid
      expect(phone_response.errors[:text]).to be_present
    end

    it 'rejects when invalid country code is present' do
      phone_response.text = '++33 1 23 45 67 89'
      expect(phone_response).not_to be_valid
      expect(phone_response.errors[:text]).to be_present
    end
  end
end
