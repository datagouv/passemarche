# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rne::MakeRequest, type: :interactor do
  include ApiResponses::RneResponses

  let(:siret) { '41816609600069' }
  let(:siren) { siret[0..8] }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/inpi/rne/unites_legales/#{siren}/extrait_rne" }
  let(:query_params) do
    {
      'context' => 'Candidature marché public',
      'recipient' => '13002526500013',
      'object' => 'Réponse appel offre'
    }
  end

  let(:successful_response_body) { rne_extrait_success_response(siren:) }

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

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'stores the HTTP response in context' do
        result = subject
        expect(result.response).to be_a(Net::HTTPSuccess)
        expect(result.response.code).to eq('200')
        expect(result.response.body).to eq(successful_response_body)
      end

      it 'makes exactly one HTTP request to the correct endpoint' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end

      it 'includes the Authorization header with Bearer token' do
        subject
        expect(a_request(:get, endpoint_url)
          .with(headers: { 'Authorization' => "Bearer #{token}" }, query: hash_including(query_params))).to have_been_made.once
      end
    end

    context 'when the API returns 404 Not Found' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: rne_extrait_not_found_response)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes a descriptive error message' do
        result = subject
        expect(result.error).to include('Unité légale non trouvée')
      end
    end

    context 'when the API returns 401 Unauthorized' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 401, body: rne_unauthorized_response)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'extracts error message from response body' do
        result = subject
        expect(result.error).to include('Votre token')
      end
    end

    context 'when API credentials are missing' do
      before do
        allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(nil)
      end

      it 'fails before making the request' do
        expect(subject).to be_failure
      end

      it 'provides appropriate error message' do
        result = subject
        expect(result.error).to eq('Missing API credentials')
      end

      it 'does not make an HTTP request' do
        subject
        expect(a_request(:get, endpoint_url)).not_to have_been_made
      end
    end

    context 'when the network is unreachable' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_raise(Errno::ENETUNREACH.new('Network is unreachable'))
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes connection error in message' do
        result = subject
        expect(result.error).to include('Connection error')
      end
    end

    context 'when the request times out' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_timeout
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes timeout error in message' do
        result = subject
        expect(result.error).to include('Timeout')
      end
    end

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }
      let(:siren) { '130025265' }
      let(:endpoint_url) { "#{base_url}v3/inpi/rne/unites_legales/#{siren}/extrait_rne" }

      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: successful_response_body)
      end

      it 'extracts SIREN from SIRET and builds the correct endpoint URL' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end
    end

    context 'with market_application context' do
      let(:market_application) { create(:market_application) }

      subject { described_class.call(params: { siret: }, market_application:) }

      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including('object' => "Réponse marché: #{market_application.public_market.name}"))
          .to_return(status: 200, body: successful_response_body)
      end

      it 'includes market name in request object parameter' do
        subject
        expect(a_request(:get, endpoint_url)
          .with(query: hash_including('object' => "Réponse marché: #{market_application.public_market.name}"))).to have_been_made
      end
    end
  end
end
