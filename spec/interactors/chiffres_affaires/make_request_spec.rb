require 'rails_helper'

RSpec.describe Dgfip::ChiffresAffaires::MakeRequest, type: :interactor do
  include ApiResponses::ChiffresAffairesResponses

  let(:siret) { '41816609600069' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/dgfip/etablissements/#{siret}/chiffres_affaires" }
  let(:successful_response_body) { chiffres_affaires_success_response }

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

    context 'when the API request is successful (HTTP 200)' do
      before do
        stub_request(:get, endpoint_url)
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
    end

    context 'when the API request is unauthorized (HTTP 401)' do
      before do
        stub_request(:get, endpoint_url)
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
    end
  end
end
