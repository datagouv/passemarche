# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insee, type: :organizer do
  include ApiResponses::InseeResponses

  let(:siret) { '41816609600069' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:api_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }
  let(:token) { 'test_token_123' }
  let(:api_entreprise_credentials) do
    OpenStruct.new(
      base_url:,
      token:
    )
  end

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(api_entreprise_credentials)
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
            body: insee_etablissement_success_response(siret:),
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

      it 'extracts the SIRET correctly' do
        result = subject
        expect(result.bundled_data.data.siret).to eq('41816609600069')
      end

      it 'extracts the category correctly' do
        result = subject
        expect(result.bundled_data.data.category).to eq('PME')
      end

      it 'sets an empty context hash in BundledData' do
        result = subject
        expect(result.bundled_data.context).to eq({})
      end

      context 'with a different category (GE)' do
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
              body: insee_etablissement_success_response(
                siret:,
                overrides: {
                  data: {
                    unite_legale: {
                      categorie_entreprise: 'GE'
                    }
                  }
                }
              ),
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'extracts the GE category correctly' do
          result = subject
          expect(result.bundled_data.data.category).to eq('GE')
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
            body: insee_unauthorized_response,
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
            body: insee_etablissement_not_found_response,
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
      let(:api_entreprise_credentials) do
        OpenStruct.new(
          base_url:,
          token: nil
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

    context 'when called with market_application (full integration)' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:, siret:) }

      let!(:siret_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_siret',
          api_name: 'Insee',
          api_key: 'siret',
          public_markets: [public_market])
      end

      let!(:category_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_categorie',
          api_name: 'Insee',
          api_key: 'category',
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
            body: insee_etablissement_success_response(siret:),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(2)
      end

      it 'populates SIRET field correctly' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
        expect(response.text).to eq('41816609600069')
      end

      it 'populates category field correctly' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: category_attribute)
        expect(response.text).to eq('PME')
      end

      it 'creates both BundledData and responses' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(market_application.market_attribute_responses.count).to eq(2)
      end
    end
  end
end
