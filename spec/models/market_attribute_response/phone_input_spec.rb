require 'rails_helper'

RSpec.describe MarketAttributeResponse::PhoneInput, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'phone_input') }
  let(:phone_response) { described_class.new(market_application:, market_attribute:) }

  describe 'validations' do
    it 'accepts a valid French phone number' do
      phone_response.text = '+33612345678'
      expect(phone_response).to be_valid
    end

    it 'accepts a valid short phone number' do
      phone_response.text = '0612345678'
      expect(phone_response).to be_valid
    end

    it 'rejects a phone number that is too long' do
      phone_response.text = '+33 6 12 34 56 78999'
      expect(phone_response).not_to be_valid
      expect(phone_response.errors[:text]).to be_present
    end

    it 'rejects a phone number with invalid characters' do
      phone_response.text = '06-12-34-56-78abc'
      expect(phone_response).not_to be_valid
      expect(phone_response.errors[:text]).to be_present
    end

    it 'accepts blank value if allowed' do
      phone_response.text = ''
      expect(phone_response).to be_valid
    end
  end
end
