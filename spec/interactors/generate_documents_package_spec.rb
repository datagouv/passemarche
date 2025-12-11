# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateDocumentsPackage, type: :interactor do
  let(:market_application) { create(:market_application) }

  before do
    allow(Zip::OutputStream).to receive(:write_buffer).and_yield(double('zip_stream', put_next_entry: nil, write: nil)).and_return(double('zip_buffer', string: 'fake zip content'))
  end

  describe '.call' do
    subject { described_class.call(market_application:) }

    context 'when buyer attestation is attached and no documents package exists' do
      before do
        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'attaches a documents package ZIP to the market application' do
        subject
        expect(market_application.documents_package).to be_attached
        expect(market_application.documents_package.content_type).to eq('application/zip')
        expect(market_application.documents_package.filename.to_s).to include("documents_package_FT#{market_application.identifier}")
      end

      it 'sets the documents_package in the context' do
        result = subject
        expect(result.documents_package).to eq(market_application.documents_package)
      end

      it 'generates ZIP content with buyer attestation' do
        zip_stream = double('zip_stream')
        expect(zip_stream).to receive(:put_next_entry).with("buyer_attestation_FT#{market_application.identifier}.pdf")
        expect(zip_stream).to receive(:write).with('fake pdf content')
        allow(market_application.buyer_attestation).to receive(:download).and_return('fake pdf content')

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end

    context 'when no buyer attestation is attached' do
      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides error message' do
        expect(subject.message).to eq('Attestation acheteur requise pour créer le package')
      end
    end

    context 'when documents package is already attached' do
      before do
        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )
        market_application.documents_package.attach(
          io: StringIO.new('fake zip content'),
          filename: 'test.zip',
          content_type: 'application/zip'
        )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides error message' do
        expect(subject.message).to eq('Documents package déjà généré')
      end
    end

    context 'when no buyer attestation exists and documents package already exists' do
      before do
        market_application.documents_package.attach(
          io: StringIO.new('fake zip content'),
          filename: 'test.zip',
          content_type: 'application/zip'
        )
      end

      it 'fails with buyer attestation error first' do
        expect(subject).to be_failure
        expect(subject.message).to eq('Attestation acheteur requise pour créer le package')
      end
    end

    context 'when market application has API-downloaded documents' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:) }
      let(:attestation_attribute) do
        create(:market_attribute, :file_upload, :from_api,
          key: 'fiscalite_attestations_fiscales',
          api_name: 'attestations_fiscales',
          api_key: 'document',
          public_markets: [public_market])
      end

      before do
        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )

        response = MarketAttributeResponse.build_for_attribute(
          attestation_attribute,
          market_application:
        )
        response.documents.attach(
          io: StringIO.new('API PDF content'),
          filename: 'attestation_fiscale_418166096.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api_attestations_fiscales', api_name: 'attestations_fiscales' }
        )
        response.save!
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'includes API document with api_ prefix in ZIP' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents/api_01_01_fiscalite_attestations_fiscales_attestation_fiscale_418166096\.pdf$})
        expect(zip_stream).to receive(:write).with('API PDF content')

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end

    context 'when market application has user-uploaded documents' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:) }
      let(:document_attribute) do
        create(:market_attribute, :file_upload,
          key: 'custom_document_field',
          public_markets: [public_market])
      end

      before do
        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )

        response = MarketAttributeResponse.build_for_attribute(
          document_attribute,
          market_application:
        )
        response.documents.attach(
          io: StringIO.new('User PDF content'),
          filename: 'user_upload.pdf',
          content_type: 'application/pdf'
        )
        response.save!
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'includes user document with user_ prefix in ZIP' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents/user_01_01_custom_document_field_user_upload\.pdf$})
        expect(zip_stream).to receive(:write).with('User PDF content')

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end

    context 'when market application has both API and user-uploaded documents' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:) }
      let(:api_attribute) do
        create(:market_attribute, :file_upload, :from_api,
          key: 'fiscalite_attestations_fiscales',
          api_name: 'attestations_fiscales',
          api_key: 'document',
          public_markets: [public_market])
      end
      let(:user_attribute) do
        create(:market_attribute, :file_upload,
          key: 'custom_document_field',
          public_markets: [public_market])
      end

      before do
        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )

        api_response = MarketAttributeResponse.build_for_attribute(
          api_attribute,
          market_application:
        )
        api_response.documents.attach(
          io: StringIO.new('API PDF content'),
          filename: 'attestation_fiscale.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api_attestations_fiscales', api_name: 'attestations_fiscales' }
        )
        api_response.save!

        user_response = MarketAttributeResponse.build_for_attribute(
          user_attribute,
          market_application:
        )
        user_response.documents.attach(
          io: StringIO.new('User PDF content'),
          filename: 'user_upload.pdf',
          content_type: 'application/pdf'
        )
        user_response.save!
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'includes both API and user documents with correct prefixes' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents/api_01_01_fiscalite_attestations_fiscales_attestation_fiscale\.pdf$})
        expect(zip_stream).to receive(:write).with('API PDF content')

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents/user_02_01_custom_document_field_user_upload\.pdf$})
        expect(zip_stream).to receive(:write).with('User PDF content')

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end
  end
end
