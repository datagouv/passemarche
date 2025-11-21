# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dgfip::MakeRequest, type: :interactor do
  include ApiResponses::DgfipResponses

  let(:siret) { '41816609600069' }
  let(:recipient_siret) { '13002526500013' }
  let(:public_market) { create(:public_market, :completed, siret: recipient_siret) }
  let(:market_application) { create(:market_application, public_market:, siret:) }
  let(:siren) { '418166096' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v4/dgfip/unites_legales/#{siren}/attestation_fiscale" }
  let(:query_params) do
    {
      'context' => 'Candidature marché public',
      'recipient' => recipient_siret,
      'object' => "Réponse marché: #{public_market.name}"
    }
  end

  let(:successful_response_body) { dgfip_attestation_fiscale_success_response(siren:) }

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(params: { siret: }, market_application:) }

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
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'stores the response in context' do
        result = subject
        expect(result.response).to be_a(Net::HTTPSuccess)
      end

      it 'extracts SIREN from SIRET (first 9 digits)' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end
    end

    context 'when the API returns an error (HTTP 404)' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(
            status: 404,
            body: dgfip_attestation_fiscale_not_found_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to include('non trouvée')
      end
    end

    context 'when network timeout occurs' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_timeout
      end

      it 'fails with timeout error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to include('Timeout')
      end
    end

    context 'when connection is refused' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_raise(Errno::ECONNREFUSED)
      end

      it 'fails with connection error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to include('Connection error')
      end
    end

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }
      let(:siren) { '130025265' }
      let(:endpoint_url) { "#{base_url}v4/dgfip/unites_legales/#{siren}/attestation_fiscale" }

      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: successful_response_body)
      end

      it 'extracts correct SIREN from SIRET' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end
    end
  end
end
