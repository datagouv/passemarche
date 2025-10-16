# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insee::MakeRequest, type: :interactor do
  include ApiResponses::InseeResponses

  let(:siret) { '41816609600069' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }
  let(:query_params) do
    {
      'context' => 'Candidature marché public',
      'recipient' => '13002526500013',
      'object' => 'Réponse appel offre'
    }
  end

  let(:successful_response_body) { insee_etablissement_success_response(siret:) }

  before do
    # Mock API credentials to prevent leaking real tokens in CI logs
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(params: { siret: }) }

    context 'when the API request is successful (HTTP 200)' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            query: hash_including(query_params),
            headers: {
              'Authorization' => "Bearer #{token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: successful_response_body,
            headers: {
              'Content-Type' => 'application/json',
              'RateLimit-Limit' => '50',
              'RateLimit-Remaining' => '47',
              'RateLimit-Reset' => '1637223155'
            }
          )
      end

      it_behaves_like 'a successful API request'
    end

    it_behaves_like 'API request error handling'

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }
      let(:endpoint_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }

      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: successful_response_body)
      end

      it 'builds the correct endpoint URL' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end
    end
  end
end
