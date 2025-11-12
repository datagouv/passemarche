# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cnetp::BuildResource, type: :interactor do
  let(:response_json) do
    {
      'data' => {
        'document_url' => 'https://storage.entreprise.api.gouv.fr/siade/1569139162-certificat_cnetp.pdf',
        'expires_in' => 7_889_238
      }
    }
  end

  let(:response) { instance_double(Net::HTTPSuccess, body: response_json.to_json) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when response contains valid JSON with document_url' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates BundledData with Resource containing cnetp_document' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(result.bundled_data.data).to be_a(Resource)
        expect(result.bundled_data.data.cnetp_document).to eq(response_json['data']['document_url'])
      end
    end

    context 'when document_url is missing from data' do
      let(:response_json) do
        {
          'data' => {
            'expires_in' => 7_889_238
          }
        }
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates Resource with nil cnetp_document' do
        result = subject
        expect(result.bundled_data.data.cnetp_document).to be_nil
      end
    end

    context 'when response body is not valid JSON' do
      let(:response) { instance_double(Net::HTTPSuccess, body: 'not valid json') }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes JSON parsing error' do
        expect(subject.error).to include('JSON')
      end
    end

    context 'when data key is missing' do
      let(:response_json) do
        {
          'meta' => {},
          'links' => {}
        }
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error about invalid JSON' do
        expect(subject.error).to include('Invalid JSON')
      end
    end
  end
end
