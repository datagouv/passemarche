require 'rails_helper'

RSpec.describe Qualibat, type: :organizer do
  include ApiResponses::QualibatResponses

  let(:siret) { '78824266700020' }
  let(:response_body) { qualibat_success_response(siret:) }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(siret:) }

    context 'when the API returns valid data' do
      before do
        allow(Qualibat::MakeRequest).to receive(:call).and_return(response)
      end

      it 'returns the certification document url' do
        result = subject
        expect(result.document_url).to eq('https://qualibat.example.com/certificat.pdf')
      end
    end

    context 'when the API returns invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: qualibat_invalid_json_response) }

      before do
        allow(Qualibat::MakeRequest).to receive(:call).and_return(response)
      end

      it 'fails and sets an error message' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when the API returns empty response' do
      let(:response) { instance_double(Net::HTTPOK, body: qualibat_empty_response) }

      before do
        allow(Qualibat::MakeRequest).to receive(:call).and_return(response)
      end

      it 'fails and sets an error message' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when the API returns a response missing data key' do
      let(:response) { instance_double(Net::HTTPOK, body: qualibat_response_without_data_key) }

      before do
        allow(Qualibat::MakeRequest).to receive(:call).and_return(response)
      end

      it 'fails and sets an error message' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end
  end
end
