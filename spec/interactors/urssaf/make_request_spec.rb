# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Urssaf::MakeRequest, type: :interactor do
  include ApiResponses::UrssafResponses

  let(:siret) { '41816609600069' }
  let(:base_url) { 'https://staging.entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:siren) { '418166096' }
  let(:endpoint_url) { "#{base_url}v4/urssaf/unites_legales/#{siren}/attestation_vigilance" }

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

    context 'when the API request is successful (HTTP 200)' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013',
              'object' => 'Réponse appel offre'
            ),
            headers: {
              'Authorization' => "Bearer #{token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: urssaf_attestation_success_response(
              overrides: {
                data: {
                  document_url: 'https://storage.entreprise.api.gouv.fr/siade/test-attestation.pdf'
                }
              }
            ).to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'stores the response in context' do
        result = subject
        expect(result.response).to be_present
        expect(result.response.body).to include('document_url')
      end
    end

    context 'when the API returns an error' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013',
              'object' => 'Réponse appel offre'
            ),
            headers: {
              'Authorization' => "Bearer #{token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 404,
            body: urssaf_attestation_error_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        result = subject
        expect(result.error).to be_present
      end
    end
  end
end
