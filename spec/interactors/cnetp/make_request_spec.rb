# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cnetp::MakeRequest, type: :interactor do
  let(:siren) { '418166096' }
  let(:recipient_siret) { '13002526500013' }
  let(:public_market) { create(:public_market, :completed, siret: recipient_siret) }
  let(:market_application) { create(:market_application, public_market:, siret: "#{siren}00069") }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/cnetp/unites_legales/#{siren}/attestation_cotisations_conges_payes_chomage_intemperies" }
  let(:query_params) do
    {
      'context' => 'Candidature marché public',
      'recipient' => recipient_siret,
      'object' => "Réponse marché: #{public_market.name}"
    }
  end

  let(:response_body) do
    {
      data: {
        document_url: 'https://storage.entreprise.api.gouv.fr/siade/1569139162-certificat_cnetp.pdf',
        expires_in: 7_889_238
      },
      links: {},
      meta: {}
    }.to_json
  end

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(params: { siren: }, market_application:) }

    context 'when API request succeeds' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            query: hash_including(query_params),
            headers: {
              'Authorization' => "Bearer #{token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'stores the response in context' do
        result = subject
        expect(result.response).to be_a(Net::HTTPSuccess)
      end

      it 'uses the SIREN in the URL' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end
    end

    context 'when API returns 404' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to be_present
      end
    end

    context 'when request times out' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_timeout
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes timeout error' do
        expect(subject.error).to include('Timeout')
      end
    end

    context 'when connection is refused' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_raise(Errno::ECONNREFUSED)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes connection error' do
        expect(subject.error).to be_present
      end
    end

    context 'when SIREN is missing' do
      subject { described_class.call(params: {}, market_application:) }

      before do
        stub_request(:get, %r{#{base_url}v3/cnetp/unites_legales//attestation})
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)
      end

      it 'fails' do
        expect(subject).to be_failure
      end
    end
  end
end
