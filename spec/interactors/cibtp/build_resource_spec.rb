# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cibtp::BuildResource, type: :interactor do
  let(:successful_response_body) do
    {
      data: {
        document_url: 'https://storage.entreprise.api.gouv.fr/siade/1569139162-certificat_cibtp.pdf',
        expires_in: 600
      },
      links: {},
      meta: {}
    }.to_json
  end

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

      it 'extracts document_url from data.document_url and stores it as cibtp_document' do
        result = subject
        expect(result.bundled_data.data.cibtp_document).to eq('https://storage.entreprise.api.gouv.fr/siade/1569139162-certificat_cibtp.pdf')
      end
    end

    context 'when document_url is missing' do
      let(:successful_response_body) do
        {
          data: {
            document_url: nil,
            expires_in: 600
          },
          links: {},
          meta: {}
        }.to_json
      end

      it 'succeeds but cibtp_document is nil' do
        result = subject
        expect(result).to be_success
        expect(result.bundled_data.data.cibtp_document).to be_nil
      end
    end

    context 'when response body is invalid JSON' do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          body: 'not valid json',
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
      let(:successful_response_body) do
        {
          errors: [{ code: '01', title: 'Error' }]
        }.to_json
      end

      it 'fails with invalid JSON error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end
  end
end
