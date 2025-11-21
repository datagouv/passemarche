# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifelec, type: :organizer do
  include ApiResponses::QualifelecResponses

  let(:siret) { '78824266700020' }
  let(:recipient_siret) { '13002526500013' }
  let(:public_market) { create(:public_market, :completed, siret: recipient_siret) }
  let(:market_application) { create(:market_application, public_market:, siret:) }
  let(:base_url) { 'https://storage.entreprise.api.gouv.fr/' }
  let(:api_url) { "#{base_url}v3/qualifelec/etablissements/#{siret}/certificats" }
  let(:token) { 'test-token-12345' }

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

    context 'when the API call and document downloads are successful' do
      let(:document_url_1) { 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-1.jpg' }
      let(:document_url_2) { 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-2.jpg' }
      let(:jpeg_header) { "\xFF\xD8\xFF".dup.force_encoding('ASCII-8BIT') }
      let(:document_body_1) { (jpeg_header.dup + ("\x00" * 200).force_encoding('ASCII-8BIT')) }
      let(:document_body_2) { (jpeg_header.dup + ("\x00" * 250).force_encoding('ASCII-8BIT')) }

      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: qualifelec_success_response,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'image/jpeg' }
          )

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'image/jpeg' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
      end

      it 'extracts multiple documents correctly' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents).to be_an(Array)
        expect(documents.size).to eq(2)

        documents.each do |document|
          expect(document).to be_a(Hash)
          expect(document[:io]).to be_a(StringIO)
          expect(document[:content_type]).to eq('image/jpeg')
        end
      end
    end

    context 'when the API returns unauthorized (401)' do
      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 401,
            body: qualifelec_unauthorized_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        result = subject
        expect(result.error).to include('Unauthorized')
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
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 404,
            body: qualifelec_not_found_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        result = subject
        expect(result.error).to include('Not Found')
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end
    end

    context 'when the API returns invalid JSON' do
      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: qualifelec_invalid_json_response,
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

    context 'when the API returns empty array' do
      let(:jpeg_header) { "\xFF\xD8\xFF".dup.force_encoding('ASCII-8BIT') }

      before do
        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => recipient_siret,
              'object' => "Réponse marché: #{public_market.name}"
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: qualifelec_empty_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data with empty documents array' do
        result = subject
        expect(result.bundled_data.data.documents).to eq([])
      end
    end

    context 'when called with market_application (full integration)' do
      let(:public_market) { create(:public_market, :completed) }
      let(:market_application) { create(:market_application, public_market:, siret:) }
      let(:jpeg_header) { "\xFF\xD8\xFF".dup.force_encoding('ASCII-8BIT') }
      let(:document_body_1) { (jpeg_header.dup + ("\x00" * 200).force_encoding('ASCII-8BIT')) }
      let(:document_body_2) { (jpeg_header.dup + ("\x00" * 250).force_encoding('ASCII-8BIT')) }

      let!(:certificate_attribute) do
        create(:market_attribute, :inline_file_upload, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_qualifelec',
          api_name: 'qualifelec',
          api_key: 'documents',
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
            body: qualifelec_success_response,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-1.jpg')
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'image/jpeg' }
          )

        stub_request(:get, 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-2.jpg')
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'image/jpeg' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses' do
        expect { subject }
          .to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'stores multiple certificate documents' do
        subject
        response =
          market_application.market_attribute_responses
            .find_by(market_attribute: certificate_attribute)

        expect(response.documents).to be_attached
        expect(response.documents.count).to eq(2)
        expect(response.source).to eq('auto')
      end

      it 'creates both BundledData and responses' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(market_application.market_attribute_responses.count).to eq(1)
      end
    end
  end
end
