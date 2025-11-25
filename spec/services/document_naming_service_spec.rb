# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentNamingService, type: :service do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:) }

  describe '#filename_mapping' do
    context 'when market application has no documents' do
      it 'returns empty hash' do
        service = described_class.new(market_application)

        expect(service.filename_mapping).to eq({})
      end
    end

    context 'when market application has user-uploaded documents' do
      let(:document_attribute) do
        create(:market_attribute, :file_upload,
          key: 'custom_document_field',
          public_markets: [public_market])
      end

      before do
        response = MarketAttributeResponse.build_for_attribute(document_attribute, market_application:)
        response.documents.attach(
          io: StringIO.new('PDF content'),
          filename: 'user_upload.pdf',
          content_type: 'application/pdf'
        )
        response.save!
      end

      it 'returns mapping with user prefix' do
        service = described_class.new(market_application)

        expect(service.filename_mapping.values.first).to include(
          original: 'user_upload.pdf',
          system: 'user_01_01_custom_document_field_user_upload.pdf'
        )
      end
    end

    context 'when market application has API-downloaded documents' do
      let(:api_attribute) do
        create(:market_attribute, :radio_with_justification_required, :from_api,
          key: 'fiscalite_attestations_fiscales',
          api_name: 'attestations_fiscales',
          api_key: 'document',
          public_markets: [public_market])
      end

      before do
        response = MarketAttributeResponse.build_for_attribute(api_attribute, market_application:)
        response.documents.attach(
          io: StringIO.new('API PDF content'),
          filename: 'attestation_fiscale.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api_attestations_fiscales', api_name: 'attestations_fiscales' }
        )
        response.save!
      end

      it 'returns mapping with api prefix' do
        service = described_class.new(market_application)

        expect(service.filename_mapping.values.first).to include(
          original: 'attestation_fiscale.pdf',
          system: 'api_01_01_fiscalite_attestations_fiscales_attestation_fiscale.pdf'
        )
      end
    end

    context 'when market application has multiple documents' do
      let(:first_attribute) do
        create(:market_attribute, :file_upload,
          key: 'first_field',
          public_markets: [public_market])
      end
      let(:second_attribute) do
        create(:market_attribute, :file_upload,
          key: 'second_field',
          public_markets: [public_market])
      end

      before do
        first_response = MarketAttributeResponse.build_for_attribute(first_attribute, market_application:)
        first_response.documents.attach(
          io: StringIO.new('First PDF'),
          filename: 'document.pdf',
          content_type: 'application/pdf'
        )
        first_response.save!

        second_response = MarketAttributeResponse.build_for_attribute(second_attribute, market_application:)
        second_response.documents.attach(
          io: StringIO.new('Second PDF'),
          filename: 'document.pdf',
          content_type: 'application/pdf'
        )
        second_response.save!
      end

      it 'returns unique system filenames for each document' do
        service = described_class.new(market_application)
        system_names = service.filename_mapping.values.map { |m| m[:system] }

        expect(system_names).to contain_exactly(
          'user_01_01_first_field_document.pdf',
          'user_02_01_second_field_document.pdf'
        )
      end
    end

    context 'when response has multiple documents' do
      let(:document_attribute) do
        create(:market_attribute, :file_upload,
          key: 'multi_upload_field',
          public_markets: [public_market])
      end

      before do
        response = MarketAttributeResponse.build_for_attribute(document_attribute, market_application:)
        response.documents.attach(
          io: StringIO.new('First PDF'),
          filename: 'first.pdf',
          content_type: 'application/pdf'
        )
        response.documents.attach(
          io: StringIO.new('Second PDF'),
          filename: 'second.pdf',
          content_type: 'application/pdf'
        )
        response.save!
      end

      it 'returns sequential doc indices for documents in same response' do
        service = described_class.new(market_application)
        system_names = service.filename_mapping.values.map { |m| m[:system] }

        expect(system_names).to contain_exactly(
          'user_01_01_multi_upload_field_first.pdf',
          'user_01_02_multi_upload_field_second.pdf'
        )
      end
    end

    it 'memoizes the mapping' do
      service = described_class.new(market_application)

      first_call = service.filename_mapping
      second_call = service.filename_mapping

      expect(first_call).to be(second_call)
    end
  end

  describe '#system_filename_for' do
    let(:document_attribute) do
      create(:market_attribute, :file_upload,
        key: 'test_field',
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

    it 'returns the system filename for a document' do
      service = described_class.new(market_application)
      document = response.documents.first

      expect(service.system_filename_for(document)).to eq('user_01_01_test_field_my_document.pdf')
    end
  end

  describe '#original_filename_for' do
    let(:document_attribute) do
      create(:market_attribute, :file_upload,
        key: 'test_field',
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

    it 'returns the original filename' do
      service = described_class.new(market_application)
      document = response.documents.first

      expect(service.original_filename_for(document)).to eq('my_document.pdf')
    end
  end

  describe '#api_document?' do
    context 'when document has api source metadata' do
      let(:api_attribute) do
        create(:market_attribute, :radio_with_justification_required, :from_api,
          key: 'api_field',
          api_name: 'test_api',
          api_key: 'document',
          public_markets: [public_market])
      end
      let!(:response) do
        r = MarketAttributeResponse.build_for_attribute(api_attribute, market_application:)
        r.documents.attach(
          io: StringIO.new('API PDF'),
          filename: 'api_doc.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api_test_api' }
        )
        r.save!
        r
      end

      it 'returns true' do
        service = described_class.new(market_application)
        document = response.documents.first

        expect(service.api_document?(document)).to be true
      end
    end

    context 'when document has no api source metadata' do
      let(:document_attribute) do
        create(:market_attribute, :file_upload,
          key: 'user_field',
          public_markets: [public_market])
      end
      let!(:response) do
        r = MarketAttributeResponse.build_for_attribute(document_attribute, market_application:)
        r.documents.attach(
          io: StringIO.new('User PDF'),
          filename: 'user_doc.pdf',
          content_type: 'application/pdf'
        )
        r.save!
        r
      end

      it 'returns false' do
        service = described_class.new(market_application)
        document = response.documents.first

        expect(service.api_document?(document)).to be false
      end
    end
  end
end
