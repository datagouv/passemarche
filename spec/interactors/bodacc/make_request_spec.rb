# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bodacc::MakeRequest, type: :interactor do
  include ApiResponses::BodaccResponses

  let(:siret) { '44306184100047' }
  let(:siren) { '443061841' }
  let(:base_url) { 'https://bodacc-datadila.opendatasoft.com/api/explore/v2.1/catalog/datasets/annonces-commerciales/records' }

  let(:successful_response_body) { bodacc_success_response }

  describe '.call' do
    subject { described_class.call(params: { siret: }) }

    context 'when the API request is successful' do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}.*/)
          .to_return(
            status: 200,
            body: successful_response_body,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'stores the response in context' do
        result = subject
        expect(result.response).to be_a(Net::HTTPSuccess)
      end

      it 'parses and stores results from response' do
        result = subject
        expect(result.records).to be_an(Array)
        expect(result.records.length).to eq(1)
      end

      it 'uses API v2.1 parameters (limit, offset, where)' do
        subject
        expect(a_request(:get, base_url).with(
          query: hash_including('limit' => '50', 'offset' => '0')
        )).to have_been_made.once
      end
    end

    context 'when custom rows parameter is provided' do
      subject { described_class.call(params: { siret: }, rows: 100) }

      before do
        stub_request(:get, /#{Regexp.escape(base_url)}/)
          .with(query: hash_including('limit' => '100'))
          .to_return(status: 200, body: successful_response_body)
      end

      it 'uses the custom limit value' do
        subject
        expect(a_request(:get, base_url).with(
          query: hash_including('limit' => '100')
        )).to have_been_made.once
      end
    end

    context 'when start parameter is provided' do
      subject { described_class.call(params: { siret: }, start: 50) }

      before do
        stub_request(:get, /#{Regexp.escape(base_url)}/)
          .with(query: hash_including('offset' => '50'))
          .to_return(status: 200, body: successful_response_body)
      end

      it 'uses the custom offset value for pagination' do
        subject
        expect(a_request(:get, base_url).with(
          query: hash_including('offset' => '50')
        )).to have_been_made.once
      end
    end

    context 'when the API returns an HTTP error' do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}/)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides an error message with HTTP code' do
        result = subject
        expect(result.error).to include('Erreur HTTP BODACC')
        expect(result.error).to include('500')
      end
    end

    context 'when the API request times out' do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}/).to_timeout
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides a timeout error message' do
        result = subject
        expect(result.error).to include('Timeout BODACC')
      end
    end

    context 'when the connection is refused' do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}/).to_raise(Errno::ECONNREFUSED)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides a connection error message' do
        result = subject
        expect(result.error).to include('Erreur de connexion BODACC')
      end
    end

    context 'when the response contains invalid JSON' do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}/)
          .to_return(status: 200, body: 'Invalid JSON{{{')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides a JSON parsing error message' do
        result = subject
        expect(result.error).to include('Réponse JSON invalide de BODACC')
      end
    end

    context 'when no SIRET is provided' do
      subject { described_class.call(params: {}) }

      before do
        stub_request(:get, /#{Regexp.escape(base_url)}/)
          .with(
            query: {
              'limit' => '50',
              'offset' => '0'
            }
          )
          .to_return(status: 200, body: successful_response_body)
      end

      it 'makes a request without where parameter' do
        subject
        expect(a_request(:get, base_url).with(
          query: {
            'limit' => '50',
            'offset' => '0'
          }
        )).to have_been_made.once
      end
    end
  end
end
