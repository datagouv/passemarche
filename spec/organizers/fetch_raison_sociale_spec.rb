# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchRaisonSociale, type: :organizer do
  include ApiResponses::InseeResponses

  let(:siret) { '13002526500013' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:api_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }
  let(:token) { 'test_token_123' }

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(siret:) }

    context 'when the API call is successful' do
      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => siret,
              'object' => 'Réponse appel offre'
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

      it 'sets raison_sociale in context' do
        expect(subject.raison_sociale).to eq('OCTO TECHNOLOGY')
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

      it 'does not set raison_sociale' do
        expect(subject.raison_sociale).to be_nil
      end
    end

    context 'when credentials are missing' do
      before do
        allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(nil)
      end

      it 'fails' do
        expect(subject).to be_failure
      end
    end
  end
end
