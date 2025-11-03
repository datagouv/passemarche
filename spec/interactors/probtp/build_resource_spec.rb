# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Probtp::BuildResource, type: :interactor do
  include ApiResponses::ProbtpResponses

  let(:successful_response_body) { probtp_attestation_success_response }

  let(:response) do
    instance_double(
      Net::HTTPSuccess,
      body: successful_response_body,
      code: '200',
      message: 'OK'
    )
  end

  describe '.call' do
    subject { described_class.call(response:) }

    context 'with valid JSON response' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data with Resource object' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(result.bundled_data.data).to be_a(Resource)
      end

      it 'extracts document_url from data key and stores it as document' do
        result = subject
        expect(result.bundled_data.data.document).to eq('https://storage.entreprise.api.gouv.fr/siade/1569139162-41816609600069-attestation_probtp.pdf')
      end
    end

    context 'when document_url is missing' do
      let(:successful_response_body) do
        probtp_attestation_success_response(
          overrides: { data: { document_url: nil } }
        )
      end

      it 'succeeds but document is nil' do
        result = subject
        expect(result).to be_success
        expect(result.bundled_data.data.document).to be_nil
      end
    end

    context 'when response body is invalid JSON' do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          body: probtp_invalid_json_response,
          code: '200',
          message: 'OK'
        )
      end

      it 'fails with invalid JSON error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when data key is missing' do
      let(:successful_response_body) { probtp_response_without_data_key }

      it 'fails with invalid JSON error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end
  end
end
