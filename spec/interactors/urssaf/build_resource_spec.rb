# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Urssaf::BuildResource, type: :interactor do
  include ApiResponses::UrssafResponses

  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when response contains valid JSON with document_url' do
      let(:response) do
        double('response', body: urssaf_attestation_success_response(
          overrides: {
            data: {
              document_url: 'https://storage.entreprise.api.gouv.fr/siade/1569139162-b99824d9c764aae19a862a0af-attestation_vigilance_acoss.pdf'
            }
          }
        ).to_json)
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data with resource' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(result.bundled_data.data).to be_a(Resource)
      end

      it 'extracts document_url from the response' do
        result = subject
        expected_url = 'https://storage.entreprise.api.gouv.fr/siade/1569139162-b99824d9c764aae19a862a0af-attestation_vigilance_acoss.pdf'
        expect(result.bundled_data.data.document).to eq(expected_url)
      end
    end

    context 'when response contains invalid JSON' do
      let(:response) { double('response', body: 'invalid json') }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when response has no data key' do
      let(:response) { double('response', body: '{}') }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when document_url is missing from data' do
      let(:response) do
        double('response', body: { data: { other_field: 'value' } }.to_json)
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets document to nil' do
        result = subject
        expect(result.bundled_data.data.document).to be_nil
      end
    end

    context 'when document_url is nil in data' do
      let(:response) do
        double('response', body: urssaf_attestation_refusal_response.to_json)
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets document to nil' do
        result = subject
        expect(result.bundled_data.data.document).to be_nil
      end
    end
  end
end
