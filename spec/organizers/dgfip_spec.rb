# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dgfip, type: :organizer do
  include ApiResponses::DgfipResponses

  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:api_url) { "#{base_url}v4/dgfip/unites_legales/#{siren}/attestation_fiscale" }
  let(:token) { 'test_token_123' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(
        base_url:,
        token:
      )
    )
  end

  describe '.call' do
    subject { described_class.call(params: { siret: }) }

    context 'when the API call and document download are successful' do
      let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-attestation_fiscale_dgfip.pdf" }
      let(:document_body) { '%PDF-1.4 fake pdf content with enough bytes to pass minimum size validation requiring at least 100 bytes total' }

      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013',
              'object' => 'Réponse appel offre'
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: dgfip_attestation_fiscale_success_response(siren:),
            headers: { 'Content-Type' => 'application/json' }
          )

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

      it 'creates a BundledData object in context' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
      end

      it 'creates a Resource object with the extracted data' do
        result = subject
        expect(result.bundled_data.data).to be_a(Resource)
      end

      it 'stores downloaded document as document hash' do
        result = subject
        document = result.bundled_data.data.document

        expect(document).to be_a(Hash)
        expect(document[:io]).to be_a(StringIO)
        expect(document[:io].read).to eq(document_body)
        expect(document[:filename]).to eq("1569139162-#{siren}-attestation_fiscale_dgfip.pdf")
        expect(document[:content_type]).to eq('application/pdf')
        expect(document[:metadata]).to include(
          source: 'api_attestations_fiscales',
          api_name: 'attestations_fiscales'
        )
      end

      it 'sets api_name to attestations_fiscales' do
        result = subject
        expect(result.api_name).to eq('attestations_fiscales')
      end

      it 'sets an empty context hash in BundledData' do
        result = subject
        expect(result.bundled_data.context).to eq({})
      end
    end

    context 'when MakeRequest fails' do
      before do
        stub_request(:get, api_url)
          .with(query: hash_including('context' => 'Candidature marché public'))
          .to_return(status: 404, body: dgfip_attestation_fiscale_not_found_response)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end

      it 'includes error message' do
        result = subject
        expect(result.error).to be_present
      end
    end

    context 'when BuildResource fails' do
      before do
        stub_request(:get, api_url)
          .with(query: hash_including('context' => 'Candidature marché public'))
          .to_return(
            status: 200,
            body: dgfip_invalid_json_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error about invalid JSON' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when document download fails' do
      let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-attestation_fiscale_dgfip.pdf" }

      before do
        stub_request(:get, api_url)
          .with(query: hash_including('context' => 'Candidature marché public'))
          .to_return(
            status: 200,
            body: dgfip_attestation_fiscale_success_response(siren:),
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, document_url)
          .to_return(status: 404, body: 'Not Found')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error about failed download' do
        result = subject
        expect(result.error).to include('Failed to download document')
        expect(result.error).to include('HTTP 404')
      end
    end

    context 'when api_name is pre-set in context' do
      subject { described_class.call(params: { siret: }, api_name: 'custom_name') }
      let(:custom_document_url) { 'https://example.com/doc.pdf' }

      before do
        stub_request(:get, api_url)
          .with(query: hash_including('context' => 'Candidature marché public'))
          .to_return(
            status: 200,
            body: dgfip_attestation_fiscale_success_response(
              siren:,
              overrides: { data: { document_url: custom_document_url } }
            )
          )

        stub_request(:get, custom_document_url)
          .to_return(
            status: 200,
            body: '%PDF-1.4 test',
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'does not override the api_name' do
        result = subject
        expect(result.api_name).to eq('custom_name')
      end
    end
  end
end
