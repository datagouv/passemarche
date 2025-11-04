require 'rails_helper'

RSpec.describe Qualibat::BuildResource, type: :interactor do
  include ApiResponses::QualibatResponses

  let(:siret) { '12345678901234' }
  let(:response_body) { qualibat_success_response }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid data' do
      it 'extracts the document_url' do
        expect(subject.bundled_data.data.document_url).to eq('https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v4_qualibat_certifications_batiment/exemple-qualibat.pdf')
      end
    end

    context 'when the response contains invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: qualibat_invalid_json_response) }

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

    context 'when the response body is empty' do
      let(:response) { instance_double(Net::HTTPOK, body: qualibat_empty_response) }

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
      let(:response) { instance_double(Net::HTTPOK, body: qualibat_response_without_data_key) }

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
