# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchBuyerName::MakeRequest, type: :interactor do
  include ApiResponses::InseeResponses

  let(:siret) { '13002526500013' }
  let(:public_market) { create(:public_market, :completed, siret:) }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }
  let(:query_params) do
    {
      'context' => 'Candidature marché public',
      'recipient' => siret,
      'object' => "Configuration marché: #{public_market.name}"
    }
  end

  let(:successful_response_body) { insee_etablissement_success_response(siret:) }

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(public_market:) }

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

      it_behaves_like 'a successful API request'

      it 'uses the public market SIRET in the endpoint URL' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end

      it 'sends the public market SIRET as recipient' do
        subject
        expect(
          a_request(:get, endpoint_url).with(query: hash_including('recipient' => siret))
        ).to have_been_made.once
      end

      it 'sends the market name as object' do
        subject
        expect(
          a_request(:get, endpoint_url)
            .with(query: hash_including('object' => "Configuration marché: #{public_market.name}"))
        ).to have_been_made.once
      end
    end

    it_behaves_like 'API request error handling'

    context 'when credentials are missing' do
      before do
        allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(nil)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error about missing credentials' do
        expect(subject.error).to eq('Missing API credentials')
      end
    end
  end
end
