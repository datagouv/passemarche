# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Probtp::DownloadDocument, type: :interactor do
  let(:siret) { '41816609600069' }
  let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siret}-attestation_probtp.pdf" }
  let(:document_body) { '%PDF-1.4 fake pdf content with enough bytes to pass minimum size validation requiring at least 100 bytes total' }
  let(:resource) { Resource.new(document: document_url) }
  let(:bundled_data) { BundledData.new(data: resource) }

  describe '.call' do
    subject { described_class.call(bundled_data:, params: { siret: }, api_name: 'probtp') }

    context 'when document is successfully downloaded' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cotisations_retraite_probtp_#{siret}.pdf\""
            }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'replaces document URL with downloaded document hash' do
        result = subject
        document = result.bundled_data.data.document

        expect(document).to be_a(Hash)
        expect(document[:io]).to be_a(StringIO)
        expect(document[:io].read).to eq(document_body)
        expect(document[:content_type]).to eq('application/pdf')
      end

      it 'uses ProBTP-specific filename with full SIRET' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq("attestation_cotisations_retraite_probtp_#{siret}.pdf")
      end

      it 'includes metadata from context' do
        result = subject
        metadata = result.bundled_data.data.document[:metadata]

        expect(metadata).to include(
          source: 'api_probtp',
          api_name: 'probtp',
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

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }
      let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siret}-attestation_probtp.pdf" }

      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'extracts filename from URL path' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq("1569139162-#{siret}-attestation_probtp.pdf")
      end
    end

    context 'when Content-Disposition header and URL filename are missing' do
      let(:document_url) { 'https://storage.entreprise.api.gouv.fr/' }
      let(:resource) { Resource.new(document: document_url) }

      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'generates filename using full SIRET from params' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq("attestation_cotisations_retraite_probtp_#{siret}.pdf")
      end
    end

    context 'when downloaded document is invalid' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: 'Not a PDF',
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about invalid PDF' do
        expect(subject.error).to include('too small')
      end
    end

    context 'when network error occurs' do
      before do
        stub_request(:get, document_url)
          .to_timeout
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes timeout error message' do
        expect(subject.error).to include('execution expired')
      end
    end
  end
end
