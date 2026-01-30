# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::EmailInput, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, :email) }
  let(:email_response) { described_class.new(market_application:, market_attribute:) }

  describe 'validations' do
    context 'with valid email addresses' do
      it 'accepts simple email' do
        email_response.text = 'user@example.com'
        expect(email_response).to be_valid
      end

      it 'accepts email with subdomain' do
        email_response.text = 'user@mail.example.com'
        expect(email_response).to be_valid
      end

      it 'accepts email with plus sign' do
        email_response.text = 'user+tag@example.com'
        expect(email_response).to be_valid
      end

      it 'accepts email with dots in local part' do
        email_response.text = 'first.last@example.com'
        expect(email_response).to be_valid
      end

      it 'accepts email with numbers' do
        email_response.text = 'user123@example123.com'
        expect(email_response).to be_valid
      end

      it 'accepts email with hyphen in domain' do
        email_response.text = 'user@my-company.com'
        expect(email_response).to be_valid
      end
    end

    context 'with invalid email addresses' do
      it 'rejects email without @' do
        email_response.text = 'userexample.com'
        expect(email_response).not_to be_valid
        expect(email_response.errors[:text]).to be_present
      end

      it 'rejects email without domain' do
        email_response.text = 'user@'
        expect(email_response).not_to be_valid
        expect(email_response.errors[:text]).to be_present
      end

      it 'rejects email without local part' do
        email_response.text = '@example.com'
        expect(email_response).not_to be_valid
        expect(email_response.errors[:text]).to be_present
      end

      it 'rejects email with spaces' do
        email_response.text = 'user @example.com'
        expect(email_response).not_to be_valid
        expect(email_response.errors[:text]).to be_present
      end

      it 'rejects email with multiple @' do
        email_response.text = 'user@@example.com'
        expect(email_response).not_to be_valid
        expect(email_response.errors[:text]).to be_present
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from TextInput' do
      expect(described_class.superclass).to eq(MarketAttributeResponse::TextInput)
    end

    it 'includes TextValidatable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::TextValidatable)
    end
  end
end
