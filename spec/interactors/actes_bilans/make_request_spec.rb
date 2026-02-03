# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActesBilans::MakeRequest, type: :interactor do
  include ApiResponses::ActesBilansResponses

  let(:siret) { '78824266700020' }
  let(:siren) { '788242667' }
  let(:recipient_siret) { '13002526500013' }
  let(:public_market) { create(:public_market, :completed, siret: recipient_siret) }
  let(:market_application) { create(:market_application, public_market:, siret:) }
  let(:base_url) { 'https://entreprise.api.gouv.fr' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/inpi/rne/unites_legales/open_data/#{siren}/actes_bilans" }
  let(:successful_response_body) { actes_bilans_success_response }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(
        base_url:,
        token:
      )
    )
  end

  describe '.call' do
    subject { described_class.call(params: { siret: }, market_application:) }

    context 'when the API request is successful (HTTP 200)' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            )
          )
          .with(
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

      it 'succeeds and stores the response' do
        result = subject
        expect(result).to be_success
        expect(result.response).to be_a(Net::HTTPSuccess)
        expect(result.response.body).to eq(successful_response_body)
      end
    end

    context 'when the API request fails (HTTP 404)' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            )
          )
          .to_return(status: 404, body: actes_bilans_not_found_response)
      end

      it 'fails and includes error message' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to include('Not Found')
      end
    end

    context 'when the API request is unauthorized (HTTP 401)' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            )
          )
          .to_return(status: 401, body: actes_bilans_unauthorized_response)
      end

      it 'fails and includes error message' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to include('Unauthorized')
      end
    end

    context 'when API credentials are missing' do
      before do
        allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
          OpenStruct.new(
            base_url:,
            token: nil
          )
        )
      end

      it 'fails with missing credentials error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Missing API credentials')
      end
    end
  end
end
