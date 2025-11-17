# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Opqibi::BuildResource, type: :interactor do
  include ApiResponses::OpqibiResponses

  let(:successful_response_body) { opqibi_success_response }

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

      it 'extracts url from data and stores it as url key' do
        result = subject
        expect(result.bundled_data.data.url).to eq('https://www.opqibi.com/fiche/1777')
      end

      it 'extracts date_delivrance_certificat from data' do
        result = subject
        expect(result.bundled_data.data.date_delivrance_certificat).to eq('2021-01-28')
      end

      it 'extracts duree_validite_certificat from data' do
        result = subject
        expect(result.bundled_data.data.duree_validite_certificat).to eq('valable un an')
      end
    end

    context 'when url is missing' do
      let(:successful_response_body) do
        opqibi_success_response(
          overrides: { data: { url: nil } }
        )
      end

      it 'succeeds but url is nil' do
        result = subject
        expect(result).to be_success
        expect(result.bundled_data.data.url).to be_nil
      end
    end

    context 'when response body is invalid JSON' do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          body: opqibi_invalid_json_response,
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
      let(:successful_response_body) { opqibi_response_without_data_key }

      it 'fails with invalid JSON error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end
  end
end
