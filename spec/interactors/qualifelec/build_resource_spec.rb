require 'rails_helper'

RSpec.describe Qualifelec::BuildResource, type: :interactor do
  include ApiResponses::QualifelecResponses

  let(:response_body) { qualifelec_success_response }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid data with multiple certificates' do
      it 'extracts all document URLs' do
        expect(subject.bundled_data.data.documents).to eq([
          'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-1.jpg',
          'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-2.jpg'
        ])
      end
    end

    context 'when the response contains a single certificate' do
      let(:response_body) { qualifelec_single_certificate_response }

      it 'extracts the single document URL' do
        expect(subject.bundled_data.data.documents).to eq([
          'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable.jpg'
        ])
      end
    end

    context 'when the response contains an empty array' do
      let(:response_body) { qualifelec_empty_response }

      it 'succeeds with empty documents array' do
        expect(subject).to be_success
        expect(subject.bundled_data.data.documents).to eq([])
      end
    end

    context 'when some certificates are missing document URLs' do
      let(:response_body) { qualifelec_response_with_missing_document_urls }

      it 'extracts only the available document URLs' do
        expect(subject.bundled_data.data.documents).to eq([
          'https://example.com/cert1.jpg',
          'https://example.com/cert3.jpg'
        ])
      end
    end

    context 'when the response contains invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: qualifelec_invalid_json_response) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message about invalid JSON' do
        expect(subject.error).to eq('Invalid JSON response')
      end

      it 'does not create bundled_data' do
        expect(subject.bundled_data).to be_nil
      end
    end

    context 'when the response is valid JSON but missing data key' do
      let(:response) { instance_double(Net::HTTPOK, body: qualifelec_response_without_data_key) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message about invalid JSON' do
        expect(subject.error).to eq('Invalid JSON response')
      end

      it 'does not create bundled_data' do
        expect(subject.bundled_data).to be_nil
      end
    end
  end
end
