# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::UrlInput, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'url_input') }
  let(:url_response) { described_class.new(market_application:, market_attribute:) }

  describe 'validations' do
    context 'with valid URLs' do
      it 'accepts URL with https' do
        url_response.text = 'https://example.com'
        expect(url_response).to be_valid
      end

      it 'accepts URL with http' do
        url_response.text = 'http://example.com'
        expect(url_response).to be_valid
      end

      it 'accepts URL without protocol' do
        url_response.text = 'example.com'
        expect(url_response).to be_valid
      end

      it 'accepts URL with www' do
        url_response.text = 'www.example.com'
        expect(url_response).to be_valid
      end

      it 'accepts URL with path' do
        url_response.text = 'https://example.com/path/to/page'
        expect(url_response).to be_valid
      end

      it 'accepts URL with query string' do
        url_response.text = 'https://example.com?param=value'
        expect(url_response).to be_valid
      end

      it 'accepts URL with hash fragment' do
        url_response.text = 'https://example.com#section'
        expect(url_response).to be_valid
      end

      it 'accepts URL with subdomain' do
        url_response.text = 'https://sub.example.com'
        expect(url_response).to be_valid
      end

      it 'accepts blank URL' do
        url_response.text = ''
        expect(url_response).to be_valid
      end
    end

    context 'with invalid URLs' do
      it 'rejects URL with spaces' do
        url_response.text = 'https://example .com'
        expect(url_response).not_to be_valid
        expect(url_response.errors[:text]).to be_present
      end

      it 'rejects URL without domain extension' do
        url_response.text = 'https://localhost'
        expect(url_response).not_to be_valid
        expect(url_response.errors[:text]).to be_present
      end

      it 'rejects just protocol' do
        url_response.text = 'https://'
        expect(url_response).not_to be_valid
        expect(url_response.errors[:text]).to be_present
      end
    end
  end

  describe 'URL normalization' do
    it 'adds https:// prefix when missing' do
      url_response.text = 'example.com'
      url_response.save!
      expect(url_response.text).to eq('https://example.com')
    end

    it 'does not modify URL with https' do
      url_response.text = 'https://example.com'
      url_response.save!
      expect(url_response.text).to eq('https://example.com')
    end

    it 'does not modify URL with http' do
      url_response.text = 'http://example.com'
      url_response.save!
      expect(url_response.text).to eq('http://example.com')
    end

    it 'does not modify blank URL' do
      url_response.text = ''
      url_response.save!
      expect(url_response.text).to eq('')
    end

    it 'adds https:// to www URLs' do
      url_response.text = 'www.example.com'
      url_response.save!
      expect(url_response.text).to eq('https://www.example.com')
    end
  end

  describe 'included concerns' do
    it 'includes TextValidatable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::TextValidatable)
    end
  end
end
