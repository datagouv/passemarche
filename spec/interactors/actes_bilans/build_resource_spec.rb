# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActesBilans::BuildResource, type: :interactor do
  include ApiResponses::ActesBilansResponses

  let(:response_body) { actes_bilans_success_response }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid data with multiple bilans' do
      it 'extracts all bilan URLs' do
        expect(subject.bundled_data.data.actes_et_bilans).to eq([
          'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple_1.pdf',
          'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple_2.pdf',
          'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple_3.pdf'
        ])
      end
    end

    context 'when the response contains a single bilan' do
      let(:response_body) { actes_bilans_single_bilan_response }

      it 'extracts the single bilan URL' do
        expect(subject.bundled_data.data.actes_et_bilans).to eq([
          'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple.pdf'
        ])
      end
    end

    context 'when the response contains an empty bilans array' do
      let(:response_body) { actes_bilans_empty_response }

      it 'succeeds with empty array' do
        expect(subject).to be_success
        expect(subject.bundled_data.data.actes_et_bilans).to eq([])
      end
    end

    context 'when some bilans are missing URLs' do
      let(:response_body) { actes_bilans_response_with_missing_urls }

      it 'extracts only the available bilan URLs' do
        expect(subject.bundled_data.data.actes_et_bilans).to eq([
          'https://example.com/bilan1.pdf',
          'https://example.com/bilan3.pdf'
        ])
      end
    end

    context 'when the response contains invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: actes_bilans_invalid_json_response) }

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
      let(:response) { instance_double(Net::HTTPOK, body: actes_bilans_response_without_data_key) }

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
