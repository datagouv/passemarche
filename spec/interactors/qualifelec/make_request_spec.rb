require 'rails_helper'

RSpec.describe Qualifelec::MakeRequest, type: :interactor do
  include ApiResponses::QualifelecResponses

  let(:siret) { '78824266700020' }
  let(:base_url) { 'https://entreprise.api.gouv.fr' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/qualifelec/etablissements/#{siret}/certificats" }
  let(:successful_response_body) { qualifelec_success_response }

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
        stub_request(:get, "#{endpoint_url}?context=Candidature%20march%C3%A9%20public&object=R%C3%A9ponse%20appel%20offre&recipient=13002526500013")
          .with(
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

      it 'succeeds and stores the response' do
        result = subject
        expect(result).to be_success
        expect(result.response).to be_a(Net::HTTPSuccess)
        expect(result.response.body).to eq(successful_response_body)
      end
    end

    context 'when the API request fails (HTTP 404)' do
      before do
        stub_request(:get, "#{endpoint_url}?context=Candidature%20march%C3%A9%20public&object=R%C3%A9ponse%20appel%20offre&recipient=13002526500013")
          .to_return(status: 404, body: { error: 'not_found' }.to_json)
      end

      it 'fails and includes error message' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to include('HTTP 404')
      end
    end

    context 'when the API request is unauthorized (HTTP 401)' do
      before do
        stub_request(:get, "#{endpoint_url}?context=Candidature%20march%C3%A9%20public&object=R%C3%A9ponse%20appel%20offre&recipient=13002526500013")
          .to_return(status: 401, body: qualifelec_unauthorized_response)
      end

      it 'fails and includes error message' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to include('Unauthorized')
      end
    end
  end
end
