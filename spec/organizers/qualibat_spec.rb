# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualibat, type: :organizer do
  include ApiResponses::QualibatResponses

  let(:siret) { '78824266700020' }
  let(:base_url) { 'https://storage.entreprise.api.gouv.fr/' }
  let(:api_url) { "#{base_url}v4/qualibat/etablissements/#{siret}/certification_batiment" }
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
    subject { described_class.call(params: { siret: }) }

    context 'when the API call and document download are successful' do
      let(:document_url) { 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v4_qualibat_certifications_batiment/exemple-qualibat.pdf' }
      let(:document_body) { '%PDF-1.4 fake qualibat document with enough bytes to pass minimum size validation requiring at least 100 bytes total' }

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
            body: qualibat_success_response,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
      end

      it 'extracts the document correctly' do
        result = subject
        expect(result.bundled_data.data.document).to be_a(Hash)
        expect(result.bundled_data.data.document[:io]).to be_a(StringIO)
        expect(result.bundled_data.data.document[:filename]).to eq('exemple-qualibat.pdf')
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
            body: qualibat_unauthorized_response,
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
              'recipient' => '13002526500013',
              'object' => 'Réponse appel offre'
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 404,
            body: qualibat_not_found_response,
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
              'recipient' => '13002526500013',
              'object' => 'Réponse appel offre'
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: qualibat_invalid_json_response,
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
      let(:document_body) { '%PDF-1.4 fake qualibat document with enough bytes to pass minimum size validation requiring at least 100 bytes total' }

      let!(:certificate_attribute) do
        create(:market_attribute, :inline_file_upload, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_qualibat',
          api_name: 'qualibat',
          api_key: 'document',
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
            body: qualibat_success_response,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the document download from the URL returned in the API response
        stub_request(:get, 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v4_qualibat_certifications_batiment/exemple-qualibat.pdf')
          .to_return(
            status: 200,
            body: document_body,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses' do
        expect { subject }
          .to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'stores the certificate document' do
        subject
        response =
          market_application.market_attribute_responses
            .find_by(market_attribute: certificate_attribute)

        expect(response.documents).to be_attached
        expect(response.documents.first.filename.to_s).to eq('exemple-qualibat.pdf')
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
