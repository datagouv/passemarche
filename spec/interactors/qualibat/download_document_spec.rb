# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualibat::DownloadDocument, type: :interactor do
  let(:siret) { '78824266700020' }
  let(:siren) { '788242667' }
  let(:document_url) { 'https://qualibat.example.com/certificat.pdf' }
  let(:document_body) { '%PDF-1.4 fake pdf content with enough bytes to pass minimum size validation requiring at least 100 bytes total' }
  let(:resource) { Resource.new(document: document_url) }
  let(:bundled_data) { BundledData.new(data: resource) }
  let(:token) { 'test-token-12345' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(token:)
    )
  end

  describe '.call' do
    subject { described_class.call(bundled_data:, params: { siret: }, api_name: 'qualibat') }

    context 'when document is successfully downloaded' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => 'attachment; filename="certificat_qualibat.pdf"'
            }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'replaces document with downloaded document hash' do
        result = subject
        document = result.bundled_data.data.document

        expect(document).to be_a(Hash)
        expect(document[:io]).to be_a(StringIO)
        expect(document[:io].read).to eq(document_body)
        expect(document[:content_type]).to eq('application/pdf')
      end

      it 'uses filename from Content-Disposition header when available' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq('certificat_qualibat.pdf')
      end

      it 'includes metadata from context' do
        result = subject
        metadata = result.bundled_data.data.document[:metadata]

        expect(metadata).to include(
          source: 'api_qualibat',
          api_name: 'qualibat',
          downloaded_at: be_a(String)
        )
      end
    end

    context 'when document_url key is missing' do
      let(:resource) { Resource.new }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about missing document' do
        expect(subject.error).to eq('Missing document in response')
      end
    end

    context 'when HTTP request fails' do
      before do
        stub_request(:get, document_url)
          .to_return(status: 404, body: 'Not Found')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to include('Failed to download document')
        expect(subject.error).to include('HTTP 404')
      end
    end

    context 'when HTTP request times out' do
      before do
        stub_request(:get, document_url)
          .to_timeout
      end

      it 'fails' do
        expect(subject).to be_failure
      end
    end

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }
      let(:siren) { '130025265' }
      let(:document_url) { 'https://qualibat.example.com/' } # No filename in URL

      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'uses correct SIREN in filename' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq("certificat_qualibat_#{siren}.pdf")
      end
    end

    context 'when Content-Disposition header is missing' do
      let(:document_url) { 'https://qualibat.example.com/' } # No filename in URL

      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'generates filename using SIREN from params' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq("certificat_qualibat_#{siren}.pdf")
      end
    end

    context 'when downloaded document is invalid' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: 'Not a PDF - just some HTML error page content that is long enough to pass size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes validation error' do
        expect(subject.error).to include('not a valid PDF')
      end
    end
  end
end
