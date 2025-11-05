require 'rails_helper'

RSpec.describe ChiffresAffaires, type: :organizer do
  include ApiResponses::ChiffresAffairesResponses

  let(:siret) { '41816609600069' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test-token-12345' }
  let(:api_url) { "#{base_url}v3/dgfip/etablissements/#{siret}/chiffres_affaires" }

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

    context 'when the API returns valid chiffres d\'affaires data' do
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
            body: chiffres_affaires_success_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
      end

      it 'extracts chiffres d\'affaires data correctly' do
        result = subject
        data = result.bundled_data.data

        expect(data.chiffres_affaires_data).to be_present
        parsed_data = JSON.parse(data.chiffres_affaires_data)

        expect(parsed_data['year_1']['turnover']).to eq(500_000)
        expect(parsed_data['year_2']['turnover']).to eq(450_000)
        expect(parsed_data['year_3']['turnover']).to eq(400_000)

        expect(parsed_data['year_1']['fiscal_year_end']).to eq('2023-12-31')
        expect(parsed_data['year_2']['fiscal_year_end']).to eq('2022-12-31')
        expect(parsed_data['year_3']['fiscal_year_end']).to eq('2021-12-31')
      end

      it 'sets the correct api_name' do
        result = subject
        expect(result.api_name).to eq('dgfip_chiffres_affaires')
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
            body: chiffres_affaires_unauthorized_response,
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
            body: chiffres_affaires_not_found_response,
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

    context 'when the API returns empty chiffres d\'affaires' do
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
            body: chiffres_affaires_empty_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data with empty data structure' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)

        data = result.bundled_data.data
        parsed_data = JSON.parse(data.chiffres_affaires_data)

        expect(parsed_data['year_1']['turnover']).to be_nil
        expect(parsed_data['year_2']['turnover']).to be_nil
        expect(parsed_data['year_3']['turnover']).to be_nil
      end
    end

    context 'when called with market_application (full integration)' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:, siret:) }

      let!(:chiffres_affaires_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'capacite_economique_financiere_chiffre_affaires_global_annuel',
          api_name: 'dgfip_chiffres_affaires',
          api_key: 'chiffres_affaires_data',
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
            body: chiffres_affaires_success_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses' do
        expect { subject }
          .to change { market_application.market_attribute_responses.count }
          .by(1)
      end

      it 'stores the chiffres d\'affaires data structure' do
        subject
        response =
          market_application.market_attribute_responses
            .find_by(market_attribute: chiffres_affaires_attribute)

        parsed_data = JSON.parse(response.text)
        expect(parsed_data).to have_key('year_1')
        expect(parsed_data).to have_key('year_2')
        expect(parsed_data).to have_key('year_3')

        expect(parsed_data['year_1']['turnover']).to eq(500_000)
        expect(parsed_data['year_1']['market_percentage']).to be_nil
        expect(parsed_data['year_1']['fiscal_year_end']).to eq('2023-12-31')
      end

      it 'creates both BundledData and responses' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(market_application.market_attribute_responses.count).to eq(1)
      end
    end
  end
end
