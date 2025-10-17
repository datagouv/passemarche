# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationStepUpdateService do
  include ApiResponses::InseeResponses
  include ApiResponses::RneResponses

  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:, siret: '41816609600069') }
  let(:token) { 'test_token_123' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(base_url:, token:)
    )
  end

  describe '.call' do
    context 'with company_identification step' do
      let(:params) { { siret: '41816609600069' } }
      let(:siren) { '418166096' }
      let(:insee_url) { "#{base_url}v3/insee/sirene/etablissements/#{params[:siret]}" }
      let(:rne_url) { "#{base_url}v3/inpi/rne/unites_legales/#{siren}/extrait_rne" }

      before do
        # Create market attributes that will be populated by APIs
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_siret',
          api_name: 'Insee',
          api_key: 'siret',
          public_markets: [public_market])

        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_nom_prenom',
          api_name: 'rne',
          api_key: 'first_name_last_name',
          public_markets: [public_market])
      end

      context 'when API calls succeed' do
        before do
          stub_request(:get, insee_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 200,
              body: insee_etablissement_success_response(siret: params[:siret]),
              headers: { 'Content-Type' => 'application/json' }
            )

          stub_request(:get, rne_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 200,
              body: rne_extrait_success_response(siren:),
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'returns success' do
          result = described_class.call(market_application, :company_identification, params)

          expect(result[:success]).to be true
        end

        it 'saves the SIRET' do
          described_class.call(market_application, :company_identification, params)

          expect(market_application.reload.siret).to eq('41816609600069')
        end

        it 'populates data from APIs' do
          described_class.call(market_application, :company_identification, params)

          expect(market_application.market_attribute_responses.count).to eq(2)
        end

        it 'has no flash messages' do
          result = described_class.call(market_application, :company_identification, params)

          expect(result[:flash_messages]).to be_empty
        end
      end

      context 'when INSEE API fails' do
        before do
          stub_request(:get, insee_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 404,
              body: insee_etablissement_not_found_response,
              headers: { 'Content-Type' => 'application/json' }
            )

          stub_request(:get, rne_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 200,
              body: rne_extrait_success_response(siren:),
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'still returns success' do
          result = described_class.call(market_application, :company_identification, params)

          expect(result[:success]).to be true
        end

        it 'marks INSEE attributes as manual_after_api_failure' do
          described_class.call(market_application, :company_identification, params)

          insee_attribute = public_market.market_attributes.find_by(api_name: 'Insee')
          response = market_application.market_attribute_responses.find_by(market_attribute: insee_attribute)

          expect(response.source).to eq('manual_after_api_failure')
        end

        it 'includes error flash message' do
          result = described_class.call(market_application, :company_identification, params)

          expect(result[:flash_messages][:alert]).to be_present
          expect(result[:flash_messages][:alert]).to include('récupérer les informations')
        end
      end

      context 'when validation fails' do
        let(:params) { { siret: 'INVALID' } }

        it 'returns failure' do
          result = described_class.call(market_application, :company_identification, params)

          expect(result[:success]).to be false
        end
      end
    end

    context 'with generic step' do
      let(:step) { :market_information }

      it 'returns success when validation passes' do
        result = described_class.call(market_application, step, {})

        expect(result[:success]).to be true
      end

      it 'reloads responses after save' do
        expect(market_application.market_attribute_responses).to receive(:reload)

        described_class.call(market_application, step, {})
      end
    end

    context 'with summary step' do
      before do
        allow(CompleteMarketApplication).to receive(:call)
          .and_return(double(success?: true))
      end

      it 'calls CompleteMarketApplication organizer' do
        expect(CompleteMarketApplication).to receive(:call)
          .with(market_application:)

        described_class.call(market_application, :summary, {})
      end

      it 'returns success with redirect' do
        result = described_class.call(market_application, :summary, {})

        expect(result[:success]).to be true
        expect(result[:redirect]).to eq(:sync_status)
      end

      context 'when completion fails' do
        before do
          allow(CompleteMarketApplication).to receive(:call)
            .and_return(double(success?: false, message: 'Completion error'))
        end

        it 'returns failure' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:success]).to be false
        end

        it 'includes error message in flash' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:flash_messages][:alert]).to eq('Completion error')
        end
      end

      context 'when an exception occurs' do
        before do
          allow(CompleteMarketApplication).to receive(:call)
            .and_raise(StandardError, 'Unexpected error')
        end

        it 'returns failure' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:success]).to be false
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error)
            .with(/Error completing market application/)

          described_class.call(market_application, :summary, {})
        end

        it 'includes generic error message in flash' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:flash_messages][:alert]).to be_present
        end
      end
    end
  end
end
