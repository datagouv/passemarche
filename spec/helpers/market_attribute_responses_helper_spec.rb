# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponsesHelper, type: :helper do
  describe '#document_display_name' do
    let(:public_market) { create(:public_market, :completed) }
    let(:market_application) { create(:market_application, public_market:) }
    let(:document_attribute) do
      create(:market_attribute, :file_upload,
        key: 'test_document_field',
        public_markets: [public_market])
    end
    let!(:response) do
      r = MarketAttributeResponse.build_for_attribute(document_attribute, market_application:)
      r.documents.attach(
        io: StringIO.new('PDF content'),
        filename: 'my_document.pdf',
        content_type: 'application/pdf'
      )
      r.save!
      r
    end
    let(:document) { response.documents.first }

    context 'when context is :web' do
      it 'returns only original filename' do
        result = helper.document_display_name(document, market_application:, context: :web)

        expect(result).to eq('my_document.pdf')
      end
    end

    context 'when context is :pdf' do
      it 'returns only original filename' do
        result = helper.document_display_name(document, market_application:, context: :pdf)

        expect(result).to eq('my_document.pdf')
      end
    end

    context 'when context is :buyer' do
      it 'returns only system filename' do
        result = helper.document_display_name(document, market_application:, context: :buyer)

        expect(result).to eq('user_01_01_test_document_field_my_document.pdf')
      end
    end

    context 'when context is nil' do
      it 'returns only original filename (same as :web)' do
        result = helper.document_display_name(document, market_application:, context: nil)

        expect(result).to eq('my_document.pdf')
      end
    end

    context 'with special characters in filename' do
      let(:special_attribute) do
        create(:market_attribute, :file_upload,
          key: 'special_document_field',
          public_markets: [public_market])
      end
      let!(:response_special) do
        r = MarketAttributeResponse.build_for_attribute(special_attribute, market_application:)
        r.documents.attach(
          io: StringIO.new('PDF content'),
          filename: 'document (1) été.pdf',
          content_type: 'application/pdf'
        )
        r.save!
        r
      end
      let(:document_special) { response_special.documents.first }

      it 'handles special characters correctly' do
        result = helper.document_display_name(document_special, market_application:, context: :web)

        expect(result).to eq('document (1) été.pdf')
      end
    end
  end
end
