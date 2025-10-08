require 'rails_helper'

RSpec.describe MarketAttributeResponse::UrlInput, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'url_input') }
  let(:url_response) do
    MarketAttributeResponse::UrlInput.new(
      market_application:,
      market_attribute:
    )
  end

  describe 'validation' do
    context 'with valid urls' do
      [
        'https://www.example.com',
        'http://example.com',
        'www.example.com',
        'example.com',
        'https://sous.domaine.example.fr',
        'www.example.fr/page?x=1#ancre'
      ].each do |valid_url|
        it "accepts '#{valid_url}'" do
          url_response.text = valid_url
          expect(url_response).to be_valid
        end
      end
    end

    context 'with invalid urls' do
      [
        'http://example',           # pas de TLD
        'example',                  # pas de TLD
        'ftp://example.com',        # schéma non accepté
        'http://',                  # incomplet
        '',                         # vide
        nil                         # nil
      ].each do |invalid_url|
        it "rejects '#{invalid_url.inspect}'" do
          url_response.text = invalid_url
          expect(url_response).not_to be_valid
        end
      end
    end
  end

  describe '#normalize_url' do
    it 'prepends https:// to www.example.com' do
      url_response.text = 'www.example.com'
      url_response.save
      expect(url_response.text).to eq('https://www.example.com')
    end

    it 'prepends https:// to example.com' do
      url_response.text = 'example.com'
      url_response.save
      expect(url_response.text).to eq('https://example.com')
    end

    it 'does not change https url' do
      url_response.text = 'https://www.example.com'
      url_response.save
      expect(url_response.text).to eq('https://www.example.com')
    end

    it 'does not change http url' do
      url_response.text = 'http://www.example.com'
      url_response.save
      expect(url_response.text).to eq('http://www.example.com')
    end
  end
end
