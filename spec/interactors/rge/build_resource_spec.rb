require 'rails_helper'

RSpec.describe Rge::BuildResource, type: :interactor do
  include ApiResponses::RgeResponses

  let(:siret) { '12345678901234' }
  let(:response_body) { rge_success_response }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid data with multiple certificates' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'extracts all certificates into documents array' do
        documents = subject.bundled_data.data.documents
        expect(documents).to be_an(Array)
        expect(documents.size).to eq(2)
      end

      it 'extracts the first certificate with correct attributes' do
        cert = subject.bundled_data.data.documents.first
        expect(cert[:url]).to eq('https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_ademe_certificats_rge/exemple-ademe-rge-certificat_qualibat.pdf')
        expect(cert[:nom_certificat]).to eq('Qualisol CESI')
        expect(cert[:domaine]).to eq('Fenêtres, volets, portes extérieures 2020')
        expect(cert[:organisme]).to eq('qualibat')
        expect(cert[:date_expiration]).to eq('2025-08-01')
      end

      it 'extracts the second certificate with correct attributes' do
        cert = subject.bundled_data.data.documents[1]
        expect(cert[:url]).to eq('https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_ademe_certificats_rge/exemple-ademe-rge-certificat_qualipv.pdf')
        expect(cert[:nom_certificat]).to eq('QualiPV Elec')
        expect(cert[:domaine]).to eq('Installation électrique 2021')
        expect(cert[:organisme]).to eq('qualit_enr')
        expect(cert[:date_expiration]).to eq('2026-01-15')
      end
    end

    context 'when the response contains a single certificate' do
      let(:response_body) { rge_success_single_certificate_response }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'extracts the single certificate' do
        documents = subject.bundled_data.data.documents
        expect(documents).to be_an(Array)
        expect(documents.size).to eq(1)
        expect(documents.first[:nom_certificat]).to eq('Qualisol CESI')
      end
    end

    context 'when the response contains an empty data array' do
      let(:response_body) { rge_empty_response }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'extracts an empty documents array' do
        documents = subject.bundled_data.data.documents
        expect(documents).to be_an(Array)
        expect(documents).to be_empty
      end
    end

    context 'when the response contains invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: rge_invalid_json_response) }

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
      let(:response) { instance_double(Net::HTTPOK, body: rge_response_without_data_key) }

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
