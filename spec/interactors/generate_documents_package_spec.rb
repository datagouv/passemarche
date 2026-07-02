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

    context 'when market application has API-downloaded documents (no lots — flat documents/ folder)' do
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

      it 'places API document in documents/' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents/api_01_01_fiscalite_attestations_fiscales_attestation_fiscale_418166096\.pdf$})
        expect(zip_stream).to receive(:write).with('API PDF content')

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end

    context 'when market application has user-uploaded documents (no lots — flat documents/ folder)' do
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

      it 'places user document in documents/' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents/user_01_01_custom_document_field_user_upload\.pdf$})
        expect(zip_stream).to receive(:write).with('User PDF content')

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end

    context 'when market application has both API and user-uploaded documents (no lots — flat documents/ folder)' do
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

      it 'places all documents in documents/' do
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

    context 'when market application has a type-specific document (CA-4 — RG2/3/4)' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:) }
      let(:works_type) { create(:market_type, :works) }
      let(:services_type) { create(:market_type, :services) }
      let(:works_attribute) do
        create(:market_attribute, :file_upload,
          key: 'references_travaux',
          market_types: [works_type],
          public_markets: [public_market])
      end

      before do
        works_lot = create(:lot, public_market:, market_type: works_type)
        services_lot = create(:lot, public_market:, market_type: services_type)
        market_application.lots << works_lot << services_lot

        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )

        response = MarketAttributeResponse.build_for_attribute(works_attribute, market_application:)
        response.documents.attach(
          io: StringIO.new('Works PDF content'),
          filename: 'references_travaux.pdf',
          content_type: 'application/pdf'
        )
        response.save!
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'places document in documents-travaux/' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents-travaux/user_01_01_references_travaux_references_travaux\.pdf$})
        expect(zip_stream).to receive(:write).with('Works PDF content')

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end

    context 'when market application has documents for Travaux and Services (CA-1 — RG1/2/3/5)' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:) }
      let(:works_type) { create(:market_type, :works) }
      let(:services_type) { create(:market_type, :services) }
      let(:common_attribute) do
        create(:market_attribute, :file_upload,
          key: 'attestation_fiscale',
          public_markets: [public_market])
      end
      let(:works_attribute) do
        create(:market_attribute, :file_upload,
          key: 'references_travaux',
          market_types: [works_type],
          public_markets: [public_market])
      end
      let(:services_attribute) do
        create(:market_attribute, :file_upload,
          key: 'references_services',
          market_types: [services_type],
          public_markets: [public_market])
      end

      before do
        works_lot = create(:lot, public_market:, market_type: works_type)
        services_lot = create(:lot, public_market:, market_type: services_type)
        market_application.lots << works_lot << services_lot

        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )

        common_response = MarketAttributeResponse.build_for_attribute(common_attribute, market_application:)
        common_response.documents.attach(io: StringIO.new('Common PDF'), filename: 'attestation.pdf', content_type: 'application/pdf')
        common_response.save!

        works_response = MarketAttributeResponse.build_for_attribute(works_attribute, market_application:)
        works_response.documents.attach(io: StringIO.new('Works PDF'), filename: 'references_travaux.pdf', content_type: 'application/pdf')
        works_response.save!

        services_response = MarketAttributeResponse.build_for_attribute(services_attribute, market_application:)
        services_response.documents.attach(io: StringIO.new('Services PDF'), filename: 'references_services.pdf', content_type: 'application/pdf')
        services_response.save!
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'places common doc in documents-communs/, type docs in their respective subfolders' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents-communs/user_01_01_attestation_fiscale_attestation\.pdf$})
        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents-travaux/user_02_01_references_travaux_references_travaux\.pdf$})
        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents-services/user_03_01_references_services_references_services\.pdf$})

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end

    context 'when attribute is shared across multiple types (CA-3 — RG6)' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:) }
      let(:works_type) { create(:market_type, :works) }
      let(:services_type) { create(:market_type, :services) }
      let(:multi_type_attribute) do
        create(:market_attribute, :file_upload,
          key: 'kbis',
          market_types: [works_type, services_type],
          public_markets: [public_market])
      end

      before do
        works_lot = create(:lot, public_market:, market_type: works_type)
        services_lot = create(:lot, public_market:, market_type: services_type)
        market_application.lots << works_lot << services_lot

        market_application.buyer_attestation.attach(
          io: StringIO.new('fake pdf content'),
          filename: "buyer_attestation_FT#{market_application.identifier}.pdf",
          content_type: 'application/pdf'
        )

        response = MarketAttributeResponse.build_for_attribute(multi_type_attribute, market_application:)
        response.documents.attach(io: StringIO.new('Kbis PDF'), filename: 'kbis.pdf', content_type: 'application/pdf')
        response.save!
      end

      it 'places multi-type document in documents-communs/ (not duplicated)' do
        zip_stream = double('zip_stream')
        allow(zip_stream).to receive(:put_next_entry)
        allow(zip_stream).to receive(:write)

        expect(zip_stream).to receive(:put_next_entry).with(%r{^documents-communs/user_01_01_kbis_kbis\.pdf$}).once

        allow(Zip::OutputStream).to receive(:write_buffer).and_yield(zip_stream).and_return(double('zip_buffer', string: 'fake zip content'))

        subject
      end
    end
  end
end
