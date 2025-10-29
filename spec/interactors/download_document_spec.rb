# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DownloadDocument, type: :interactor do
  let(:document_url) { 'https://storage.entreprise.api.gouv.fr/documents/test_document.pdf' }
  let(:document_body) { '%PDF-1.4 fake pdf content with enough bytes to pass minimum size validation requiring at least 100 bytes total' }
  let(:token) { 'test_bearer_token_123' }
  let(:api_name) { 'test_api' }
  let(:resource) { Resource.new(document_url:) }
  let(:bundled_data) { BundledData.new(data: resource) }

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(bundled_data:, api_name:) }

    context 'when document is successfully downloaded' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'replaces document_url with document hash in bundled_data' do
        result = subject
        document = result.bundled_data.data.document

        expect(document).to be_a(Hash)
        expect(document[:io]).to be_a(StringIO)
        expect(document[:io].read).to eq(document_body)
        expect(document[:filename]).to eq('test_document.pdf')
        expect(document[:content_type]).to eq('application/pdf')
        expect(document[:metadata]).to include(
          source: 'api_test_api',
          api_name: 'test_api',
          downloaded_at: be_a(String)
        )
      end

      it 'does not send Authorization header' do
        subject
        expect(a_request(:get, document_url)
          .with { |req| !req.headers.key?('Authorization') })
          .to have_been_made.once
      end
    end

    context 'when bundled_data is missing' do
      subject { described_class.call }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Missing bundled_data')
      end
    end

    context 'when document_url is missing in response' do
      let(:resource) { Resource.new }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Missing document_url in response')
      end
    end

    context 'when document_url is blank' do
      let(:resource) { Resource.new(document_url: '') }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Missing document_url in response')
      end
    end

    context 'when HTTP request returns error (404)' do
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

    context 'when HTTP request returns error (500)' do
      before do
        stub_request(:get, document_url)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to include('Failed to download document')
        expect(subject.error).to include('HTTP 500')
      end
    end

    context 'when network timeout occurs' do
      before do
        stub_request(:get, document_url).to_timeout
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to include('Failed to download document')
        expect(subject.error).to include('execution expired')
      end
    end

    context 'when connection is refused' do
      before do
        stub_request(:get, document_url).to_raise(Errno::ECONNREFUSED)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to include('Failed to download document')
        expect(subject.error).to include('Connection refused')
      end
    end

    context 'filename extraction' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers:
          )
      end

      context 'when Content-Disposition header is present with quoted filename' do
        let(:headers) do
          {
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="official_document.pdf"'
          }
        end

        it 'extracts filename from header' do
          result = subject
          expect(result.bundled_data.data.document[:filename]).to eq('official_document.pdf')
        end
      end

      context 'when Content-Disposition header is present without quotes' do
        let(:headers) do
          {
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename=unquoted_document.pdf'
          }
        end

        it 'extracts filename from header' do
          result = subject
          expect(result.bundled_data.data.document[:filename]).to eq('unquoted_document.pdf')
        end
      end

      context 'when Content-Disposition header is missing' do
        let(:headers) { { 'Content-Type' => 'application/pdf' } }

        it 'extracts filename from URL path' do
          result = subject
          expect(result.bundled_data.data.document[:filename]).to eq('test_document.pdf')
        end
      end

      context 'when URL path has no filename' do
        let(:document_url) { 'https://storage.entreprise.api.gouv.fr/' }
        let(:headers) { { 'Content-Type' => 'application/pdf' } }

        it 'generates a fallback filename' do
          result = subject
          filename = result.bundled_data.data.document[:filename]
          expect(filename).to match(/^document_\d+\.pdf$/)
        end
      end
    end

    context 'content type extraction' do
      before do
        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers:
          )
      end

      context 'when Content-Type header is present' do
        let(:headers) { { 'Content-Type' => 'application/pdf' } }

        it 'extracts content type' do
          result = subject
          expect(result.bundled_data.data.document[:content_type]).to eq('application/pdf')
        end
      end

      context 'when Content-Type header has charset' do
        let(:headers) { { 'Content-Type' => 'application/pdf; charset=utf-8' } }

        it 'extracts only the content type without charset' do
          result = subject
          expect(result.bundled_data.data.document[:content_type]).to eq('application/pdf')
        end
      end

      context 'when Content-Type header is missing' do
        let(:headers) { {} }

        it 'uses default content type' do
          result = subject
          expect(result.bundled_data.data.document[:content_type]).to eq('application/octet-stream')
        end
      end
    end

    context 'PDF validation' do
      context 'when downloaded file is not a valid PDF' do
        before do
          stub_request(:get, document_url)
            .to_return(
              status: 200,
              body: '<html>Error page that is long enough to exceed 100 bytes minimum but is not a PDF file at all, just HTML</html>',
              headers: { 'Content-Type' => 'application/pdf' }
            )
        end

        it 'fails' do
          expect(subject).to be_failure
        end

        it 'includes PDF validation error message' do
          expect(subject.error).to include('not a valid PDF')
        end
      end

      context 'when downloaded file is too small' do
        before do
          stub_request(:get, document_url)
            .to_return(
              status: 200,
              body: '%PDF-',
              headers: { 'Content-Type' => 'application/pdf' }
            )
        end

        it 'fails' do
          expect(subject).to be_failure
        end

        it 'includes file size error message' do
          expect(subject.error).to include('too small')
          expect(subject.error).to include('5 bytes')
        end
      end

      context 'when downloaded file is empty' do
        before do
          stub_request(:get, document_url)
            .to_return(
              status: 200,
              body: '',
              headers: { 'Content-Type' => 'application/pdf' }
            )
        end

        it 'fails' do
          expect(subject).to be_failure
        end

        it 'includes file size error message' do
          expect(subject.error).to include('too small')
          expect(subject.error).to include('0 bytes')
        end
      end

      context 'when valid PDF is downloaded' do
        before do
          stub_request(:get, document_url)
            .to_return(
              status: 200,
              body: '%PDF-1.7 valid content with sufficient length to pass validation checks requiring at least 100 bytes total',
              headers: { 'Content-Type' => 'application/pdf' }
            )
        end

        it 'succeeds' do
          expect(subject).to be_success
        end

        it 'stores the valid PDF document' do
          result = subject
          document = result.bundled_data.data.document
          expect(document[:io].read).to start_with('%PDF-')
        end
      end
    end
  end
end
