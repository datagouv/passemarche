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

    context 'when the API call is successful' do
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

      it 'stores document_url as document key' do
        result = subject
        expect(result.bundled_data.data.document).to eq('https://storage.entreprise.api.gouv.fr/siade/1569139162-418166096-attestation_fiscale_dgfip.pdf')
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

    context 'when api_name is pre-set in context' do
      subject { described_class.call(params: { siret: }, api_name: 'custom_name') }

      before do
        stub_request(:get, api_url)
          .with(query: hash_including('context' => 'Candidature marché public'))
          .to_return(
            status: 200,
            body: dgfip_attestation_fiscale_success_response(
              siren:,
              overrides: { data: { document_url: 'https://example.com/doc.pdf' } }
            )
          )
      end

      it 'does not override the api_name' do
        result = subject
        expect(result.api_name).to eq('custom_name')
      end
    end
  end
end
