# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportSocleDeBaseCsvService do
  let(:works_type) { create(:market_type, :works) }
  let(:services_type) { create(:market_type, :services) }

  let!(:category) { create(:category, key: 'identite_entreprise', buyer_label: 'Identité', candidate_label: 'Identity') }
  let!(:subcategory) do
    create(:subcategory, category:, key: 'identite_identification',
      buyer_label: 'Identification', candidate_label: 'ID')
  end

  let!(:api_attr) do
    create(:market_attribute,
      key: 'test_siret',
      category_key: 'identite_entreprise',
      subcategory_key: 'identite_identification',
      subcategory:,
      mandatory: true,
      api_name: 'Insee',
      api_key: 'siret',
      buyer_name: 'SIRET acheteur',
      buyer_description: 'Description acheteur',
      candidate_name: 'SIRET candidat',
      candidate_description: 'Description candidat',
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

  let(:attributes) { MarketAttribute.active.ordered.includes(:market_types, subcategory: :category) }

  describe '#perform' do
    subject do
      service = described_class.new(market_attributes: attributes)
      service.perform
      service
    end

    it 'generates a CSV with correct headers' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      expect(csv.headers).to eq(described_class::HEADERS)
    end

    it 'includes all attributes as rows' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      keys = csv.map { |row| row['Clé'] } # rubocop:disable Rails/Pluck
      expect(keys).to include('test_siret', 'test_attestation')
    end

    it 'exports category and subcategory keys' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Catégorie (clé)']).to eq('identite_entreprise')
      expect(siret_row['Sous-catégorie (clé)']).to eq('identite_identification')
    end

    it 'exports buyer and candidate labels' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Catégorie acheteur']).to eq('Identité')
      expect(siret_row['Sous-catégorie acheteur']).to eq('Identification')
      expect(siret_row['Catégorie candidat']).to eq('Identity')
      expect(siret_row['Sous-catégorie candidat']).to eq('ID')
    end

    it 'exports descriptions' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Description acheteur']).to eq('Description acheteur')
      expect(siret_row['Description candidat']).to eq('Description candidat')
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

    it 'exports raw api_name for api attributes' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Source (api_name)']).to eq('Insee')
    end

    it 'exports blank api_name for manual attributes' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      attestation_row = csv.find { |row| row['Clé'] == 'test_attestation' }
      expect(attestation_row['Source (api_name)']).to be_nil
    end

    it 'exports api_key' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Clé API']).to eq('siret')
    end

    it 'exports raw input_type enum key' do
      csv = CSV.parse(subject.result[:csv_data], col_sep: ';', headers: true)
      siret_row = csv.find { |row| row['Clé'] == 'test_siret' }
      expect(siret_row['Type de saisie']).to eq('text_input')
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
        expect(csv.headers).to eq(described_class::HEADERS)
      end
    end
  end
end
