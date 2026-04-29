# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchBuyerName, type: :organizer do
  include ApiResponses::InseeResponses

  let(:siret) { '13002526500013' }
  let(:public_market) { create(:public_market, :completed, siret:) }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:api_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }
  let(:token) { 'test_token_123' }

  ApiEntrepriseCredentials = Struct.new(:base_url, :token)

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      ApiEntrepriseCredentials.new(base_url, token)
    )
  end

  describe '.call' do
    subject { described_class.call(public_market:) }

    context 'when the API call is successful' do
      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => siret,
              'object' => "Configuration marché: #{public_market.name}"
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: insee_etablissement_success_response(siret:),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets buyer_name in context' do
        expect(subject.buyer_name).to eq('OCTO TECHNOLOGY')
      end
    end

    context 'when the API call fails' do
      before do
        stub_request(:get, api_url)
          .with(query: hash_including({}))
          .to_return(status: 404, body: '{}')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'does not set buyer_name' do
        expect(subject.buyer_name).to be_nil
      end
    end

    context 'when credentials are missing' do
      before do
        allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
          OpenStruct.new(base_url:, token: nil)
        )
      end

      it 'fails' do
        expect(subject).to be_failure
      end
    end
  end
end
