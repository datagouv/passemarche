# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dgfip::DownloadDocument, type: :interactor do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-attestation_fiscale_dgfip.pdf" }
  let(:document_body) { '%PDF-1.4 fake pdf content' }
  let(:token) { 'test_bearer_token_123' }
  let(:resource) { Resource.new(document: document_url) }
  let(:bundled_data) { BundledData.new(data: resource) }

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(bundled_data:, params: { siret: }, api_name: 'attestations_fiscales') }

    context 'when document is successfully downloaded' do
      before do
        stub_request(:get, document_url)
          .with(headers: { 'Authorization' => "Bearer #{token}" })
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_fiscale_#{siren}.pdf\""
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

      it 'uses DGFIP-specific filename with SIREN' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq("attestation_fiscale_#{siren}.pdf")
      end

      it 'includes metadata from context' do
        result = subject
        metadata = result.bundled_data.data.document[:metadata]

        expect(metadata).to include(
          source: 'api_attestations_fiscales',
          api_name: 'attestations_fiscales',
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
      let(:siren) { '130025265' }
      let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-attestation_fiscale_dgfip.pdf" }

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
        expect(result.bundled_data.data.document[:filename]).to eq("1569139162-#{siren}-attestation_fiscale_dgfip.pdf")
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

      it 'generates filename using SIREN from params' do
        result = subject
        expect(result.bundled_data.data.document[:filename]).to eq("attestation_fiscale_#{siren}.pdf")
      end
    end
  end
end
