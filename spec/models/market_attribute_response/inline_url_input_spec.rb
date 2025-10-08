require 'rails_helper'

RSpec.describe MarketAttributeResponse::InlineUrlInput, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'inline_url_input') }
  let(:inline_url_input) do
    MarketAttributeResponse::InlineUrlInput.new(
      market_application:,
      market_attribute:
    )
  end

  describe 'inheritance' do
    it 'inherits from UrlInput' do
      expect(described_class.superclass).to eq(MarketAttributeResponse::UrlInput)
    end

    it 'includes TextValidatable concern through parent' do
      expect(inline_url_input).to respond_to(:text)
    end
  end

  describe 'validation' do
    context 'with valid urls' do
      [
        'https://www.example.com',
        'http://example.com',
        'www.example.com',
        'example.com'
      ].each do |valid_url|
        it "accepts '#{valid_url}'" do
          inline_url_input.text = valid_url
          expect(inline_url_input).to be_valid
        end
      end
    end

    context 'with invalid urls' do
      [
        'http://example',
        'example',
        'ftp://example.com',
        '',
        nil
      ].each do |invalid_url|
        it "rejects '#{invalid_url.inspect}'" do
          inline_url_input.text = invalid_url
          expect(inline_url_input).not_to be_valid
        end
      end
    end
  end

  describe '#normalize_url' do
    it 'prepends https:// to www.example.com' do
      inline_url_input.text = 'www.example.com'
      inline_url_input.save
      expect(inline_url_input.text).to eq('https://www.example.com')
    end

    it 'prepends https:// to example.com' do
      inline_url_input.text = 'example.com'
      inline_url_input.save
      expect(inline_url_input.text).to eq('https://example.com')
    end

    it 'does not change https url' do
      inline_url_input.text = 'https://www.example.com'
      inline_url_input.save
      expect(inline_url_input.text).to eq('https://www.example.com')
    end
  end

  describe 'STI type' do
    it 'sets correct type' do
      inline_url_input.text = 'https://example.com'
      inline_url_input.save
      expect(inline_url_input.type).to eq('InlineUrlInput')
    end
  end
end
