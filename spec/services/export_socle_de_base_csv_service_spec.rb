# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportSocleDeBaseCsvService do
  let(:works_type) { create(:market_type, :works) }
  let(:services_type) { create(:market_type, :services) }

  let!(:api_attr) do
    create(:market_attribute,
      key: 'test_siret',
      category_key: 'identite_entreprise',
      subcategory_key: 'identite_identification',
      mandatory: true,
      api_name: 'Insee',
      api_key: 'siret',
      input_type: :text_input,
      position: 1,
      market_types: [works_type, services_type])
  end

  let!(:manual_attr) do
    create(:market_attribute,
      key: 'test_attestation',
      category_key: 'motifs_exclusion',
      subcategory_key: 'motifs_fiscales',
      mandatory: false,
      input_type: :file_upload,
      position: 2,
      market_types: [works_type])
  end

  let(:attributes) { MarketAttribute.active.ordered.includes(:market_types) }

  describe '#perform' do
    subject do
      service = described_class.new(market_attributes: attributes)
      service.perform
      service
    end

    it 'succeeds' do
      expect(subject).to be_success
    end

    it 'generates a CSV with correct headers' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      expect(csv.headers).to include('Clé', 'Catégorie acheteur', 'Obligatoire', 'Source')
    end

    it 'includes all attributes as rows' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      keys = csv.map { |row| row['Clé'] } # rubocop:disable Rails/Pluck
      expect(keys).to include('test_siret', 'test_attestation')
    end

    it 'marks mandatory attribute as Oui' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Obligatoire']).to eq('Oui')
    end

    it 'marks optional attribute as Non' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      attestation_row = csv.find { |row| row['Clé'] == 'test_attestation' }
      expect(attestation_row['Obligatoire']).to eq('Non')
    end

    it 'shows API source for api attributes' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Source']).to include('API')
    end

    it 'shows Manuel source for manual attributes' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      attestation_row = csv.find { |row| row['Clé'] == 'test_attestation' }
      expect(attestation_row['Source']).to eq('Manuel')
    end

    it 'lists market types' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Types de marché']).to include('works')
      expect(siret_row['Types de marché']).to include('services')
    end

    it 'generates filename with current date' do
      expect(subject.result[:filename]).to eq("socle-de-base-#{Date.current}.csv")
    end

    it 'uses semicolon as separator' do
      lines = subject.result[:csv_data].lines
      expect(lines.first).to include(';')
    end

    context 'with empty collection' do
      let(:attributes) { MarketAttribute.none }

      it 'generates CSV with headers only' do
        csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
        expect(csv.count).to eq(0)
        expect(csv.headers).to include('Clé')
      end
    end
  end
end
