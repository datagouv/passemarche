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

  describe 'OPQIBI metadata accessors' do
    let(:market_attribute) do
      create(:market_attribute, input_type: 'inline_url_input', api_name: 'opqibi')
    end

    describe '#date_delivrance_certificat' do
      it 'returns the date from value hash' do
        inline_url_input.value = { 'date_delivrance_certificat' => '2021-01-28' }
        expect(inline_url_input.date_delivrance_certificat).to eq('2021-01-28')
      end

      it 'returns nil when value is nil' do
        inline_url_input.value = nil
        expect(inline_url_input.date_delivrance_certificat).to be_nil
      end

      it 'returns nil when key is missing' do
        inline_url_input.value = { 'text' => 'https://example.com' }
        expect(inline_url_input.date_delivrance_certificat).to be_nil
      end
    end

    describe '#duree_validite_certificat' do
      it 'returns the duration from value hash' do
        inline_url_input.value = { 'duree_validite_certificat' => 'valable un an' }
        expect(inline_url_input.duree_validite_certificat).to eq('valable un an')
      end

      it 'returns nil when value is nil' do
        inline_url_input.value = nil
        expect(inline_url_input.duree_validite_certificat).to be_nil
      end

      it 'returns nil when key is missing' do
        inline_url_input.value = { 'text' => 'https://example.com' }
        expect(inline_url_input.duree_validite_certificat).to be_nil
      end
    end

    describe '#formatted_date_delivrance' do
      it 'parses valid ISO date' do
        inline_url_input.value = { 'date_delivrance_certificat' => '2021-01-28' }
        expect(inline_url_input.formatted_date_delivrance).to eq(Date.parse('2021-01-28'))
      end

      it 'returns nil for invalid date' do
        inline_url_input.value = { 'date_delivrance_certificat' => 'invalid' }
        expect(inline_url_input.formatted_date_delivrance).to be_nil
      end

      it 'returns nil for blank date' do
        inline_url_input.value = { 'date_delivrance_certificat' => '' }
        expect(inline_url_input.formatted_date_delivrance).to be_nil
      end

      it 'returns nil when date is missing' do
        inline_url_input.value = { 'text' => 'https://example.com' }
        expect(inline_url_input.formatted_date_delivrance).to be_nil
      end
    end

    describe '#opqibi_metadata?' do
      it 'returns true when OPQIBI with date metadata' do
        inline_url_input.value = { 'date_delivrance_certificat' => '2021-01-28' }
        expect(inline_url_input.opqibi_metadata?).to be true
      end

      it 'returns true when OPQIBI with duration metadata' do
        inline_url_input.value = { 'duree_validite_certificat' => 'valable un an' }
        expect(inline_url_input.opqibi_metadata?).to be true
      end

      it 'returns true when OPQIBI with both metadata' do
        inline_url_input.value = {
          'date_delivrance_certificat' => '2021-01-28',
          'duree_validite_certificat' => 'valable un an'
        }
        expect(inline_url_input.opqibi_metadata?).to be true
      end

      it 'returns false when OPQIBI without metadata' do
        inline_url_input.value = { 'text' => 'https://example.com' }
        expect(inline_url_input.opqibi_metadata?).to be false
      end

      it 'returns false when not OPQIBI' do
        non_opqibi_attribute = create(:market_attribute, input_type: 'inline_url_input', api_name: 'other')
        non_opqibi_input = MarketAttributeResponse::InlineUrlInput.new(
          market_application:,
          market_attribute: non_opqibi_attribute
        )
        non_opqibi_input.value = { 'date_delivrance_certificat' => '2021-01-28' }
        expect(non_opqibi_input.opqibi_metadata?).to be false
      end
    end
  end
end
