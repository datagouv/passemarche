# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateDocumentsPackage, type: :interactor do
  let(:market_application) { create(:market_application, siret: nil) }

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
  end
end
