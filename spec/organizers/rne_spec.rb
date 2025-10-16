# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rne, type: :organizer do
  include ApiResponses::RneResponses

  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:api_url) { "#{base_url}v3/inpi/rne/unites_legales/#{siren}/extrait_rne" }
  let(:token) { 'test_token_123' }

  before do
    # Mock API credentials to prevent leaking real tokens in CI logs
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
            body: rne_extrait_success_response(siren:),
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

      it 'extracts the first_name_last_name correctly' do
        result = subject
        expect(result.bundled_data.data.first_name_last_name).to eq('SOPHIE MARTIN')
      end

      it 'extracts the head_office_address correctly' do
        result = subject
        expect(result.bundled_data.data.head_office_address).to eq('50 AVENUE DES CHAMPS ÉLYSÉES, 75008 PARIS 8, FRANCE')
      end

      it 'sets an empty context hash in BundledData' do
        result = subject
        expect(result.bundled_data.context).to eq({})
      end

      context 'with different director names' do
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
              body: rne_extrait_success_response(
                siren:,
                overrides: {
                  data: {
                    dirigeants_et_associes: [
                      {
                        qualite: 'Président',
                        nom: 'DUPONT',
                        prenom: 'JEAN',
                        date_naissance: '03-1980',
                        commune_residence: 'LYON'
                      }
                    ]
                  }
                }
              ),
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'extracts the director name correctly' do
          result = subject
          expect(result.bundled_data.data.first_name_last_name).to eq('JEAN DUPONT')
        end
      end
    end

    context 'when the API returns unauthorized (401)' do
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
            status: 401,
            body: rne_unauthorized_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        result = subject
        expect(result.error).to be_present
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end
    end

    context 'when the API returns not found (404)' do
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
            status: 404,
            body: rne_extrait_not_found_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        result = subject
        expect(result.error).to be_present
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end
    end

    context 'when the API token is missing' do
      before do
        # Override credentials mock to test missing token scenario
        allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
          OpenStruct.new(
            base_url:,
            token: nil
          )
        )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        result = subject
        expect(result.error).to eq('Missing API credentials')
      end
    end

    context 'when the API returns invalid JSON' do
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
            body: rne_invalid_json_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message about invalid JSON' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end
    end

    context 'when called with market_application (full integration)' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:, siret:) }

      let!(:director_name_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_nom_prenom',
          api_name: 'rne',
          api_key: 'first_name_last_name',
          public_markets: [public_market])
      end

      let!(:head_office_address_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_adresse_siege_social',
          api_name: 'rne',
          api_key: 'head_office_address',
          public_markets: [public_market])
      end

      subject { described_class.call(params: { siret: }, market_application:) }

      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013',
              'object' => "Réponse marché: #{public_market.name}"
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: rne_extrait_success_response(siren:),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(2)
      end

      it 'populates director name field correctly' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: director_name_attribute)
        expect(response.text).to eq('SOPHIE MARTIN')
      end

      it 'populates head office address field correctly' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: head_office_address_attribute)
        expect(response.text).to eq('50 AVENUE DES CHAMPS ÉLYSÉES, 75008 PARIS 8, FRANCE')
      end

      it 'creates both BundledData and responses' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(market_application.market_attribute_responses.count).to eq(2)
      end

      it 'marks responses as auto-populated' do
        subject
        responses = market_application.market_attribute_responses
        expect(responses.all?(&:auto?)).to be true
      end
    end
  end
end
