# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cibtp::DownloadDocument, type: :interactor do
  let(:siret) { '41816609600069' }
  let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siret}-certificat_cibtp.pdf" }
  let(:document_body) { '%PDF-1.4 fake pdf content with enough bytes to pass minimum size validation requiring at least 100 bytes total' }
  let(:resource) { Resource.new(cibtp_document: document_url) }
  let(:bundled_data) { BundledData.new(data: resource) }

  describe '.call' do
    subject { described_class.call(bundled_data:, params: { siret: }, api_name: 'cibtp') }

    context 'when document is successfully downloaded' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cibtp_#{siret}.pdf\""
            }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'replaces document URL with downloaded document hash' do
        result = subject
        document = result.bundled_data.data.cibtp_document

        expect(document).to be_a(Hash)
        expect(document[:io]).to be_a(StringIO)
        expect(document[:io].read).to eq(document_body)
        expect(document[:content_type]).to eq('application/pdf')
      end

      it 'uses CIBTP-specific filename with full SIRET' do
        result = subject
        expect(result.bundled_data.data.cibtp_document[:filename]).to eq("attestation_cibtp_#{siret}.pdf")
      end

      it 'includes metadata from context' do
        result = subject
        metadata = result.bundled_data.data.cibtp_document[:metadata]

        expect(metadata).to include(
          source: 'api_cibtp',
          api_name: 'cibtp',
          downloaded_at: be_a(String)
        )
      end
    end

    context 'when document key is missing' do
      let(:resource) { Resource.new }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about missing document' do
        expect(subject.error).to eq('Missing cibtp_document in response')
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
        expect(subject.error).to include('Failed to download')
      end
    end

    context 'when downloaded content is not a PDF' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: 'not a pdf content',
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error about file being too small' do
        expect(subject.error).to include('too small')
      end
    end
  end
end
