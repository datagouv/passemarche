# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportSocleDeBaseCsvService do
  let!(:works_type) { create(:market_type, :works) }
  let!(:services_type) { create(:market_type, :services) }

  let(:csv_path) { Rails.root.join('spec/fixtures/files/socle_de_base_import.csv') }

  describe '.call' do
    context 'with a valid CSV file' do
      subject(:result) { described_class.call(csv_file: csv_path) }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'creates market attributes from the CSV' do
        expect { result }.to change(MarketAttribute, :count).by(2)
      end

      it 'assigns correct attributes to API field' do
        result
        attr = MarketAttribute.find_by(key: 'test_siret')
        expect(attr).to have_attributes(
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_identification',
          buyer_name: 'Numéro SIRET',
          buyer_description: "Le numéro SIRET de l'entreprise",
          candidate_name: 'Your SIRET',
          candidate_description: 'Your company SIRET number',
          mandatory: true,
          api_name: 'Insee',
          api_key: 'siret',
          input_type: 'text_input',
          position: 0
        )
      end

      it 'assigns correct attributes to manual field' do
        result
        attr = MarketAttribute.find_by(key: 'test_attestation')
        expect(attr).to have_attributes(
          mandatory: false,
          api_name: nil,
          api_key: nil,
          input_type: 'file_upload',
          position: 1
        )
      end

      it 'assigns market types from comma-separated codes' do
        result
        attr = MarketAttribute.find_by(key: 'test_siret')
        expect(attr.market_types.map(&:code)).to contain_exactly('works', 'services')
      end

      it 'creates categories from the CSV' do
        expect { result }.to change(Category, :count).by(2)
      end

      it 'assigns buyer and candidate labels to categories' do
        result
        category = Category.find_by(key: 'identite_entreprise')
        expect(category).to have_attributes(
          buyer_label: 'Identité entreprise',
          candidate_label: 'Identity'
        )
      end

      it 'creates subcategories from the CSV' do
        expect { result }.to change(Subcategory, :count).by(2)
      end

      it 'links subcategory to market attribute' do
        result
        attr = MarketAttribute.find_by(key: 'test_siret')
        expect(attr.subcategory.key).to eq('identite_identification')
      end

      it 'reports creation statistics' do
        expect(result.statistics[:created]).to eq(2)
        expect(result.statistics[:updated]).to eq(0)
        expect(result.statistics[:skipped]).to eq(0)
      end
    end

    context 'when updating existing records' do
      let!(:existing) do
        create(:market_attribute,
          key: 'test_siret',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_identification',
          buyer_name: 'Old name',
          input_type: :text_input)
      end

      it 'updates existing attributes' do
        described_class.call(csv_file: csv_path)
        existing.reload
        expect(existing.buyer_name).to eq('Numéro SIRET')
      end

      it 'reports update statistics' do
        result = described_class.call(csv_file: csv_path)
        expect(result.statistics[:updated]).to eq(1)
        expect(result.statistics[:created]).to eq(1)
      end
    end

    context 'soft-deleting missing records' do
      let!(:orphan) do
        create(:market_attribute,
          key: 'orphan_field',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_identification')
      end

      it 'soft-deletes attributes not present in the CSV' do
        described_class.call(csv_file: csv_path)
        expect(orphan.reload.deleted_at).to be_present
      end

      it 'reports soft-delete statistics' do
        result = described_class.call(csv_file: csv_path)
        expect(result.statistics[:soft_deleted]).to eq(1)
      end

      it 'does not soft-delete already archived attributes' do
        orphan.update!(deleted_at: 1.day.ago)
        result = described_class.call(csv_file: csv_path)
        expect(result.statistics[:soft_deleted]).to eq(0)
      end
    end

    context 'when no rows are successfully imported' do
      let!(:existing) do
        create(:market_attribute,
          key: 'existing_field',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_identification')
      end

      let(:empty_csv) { Tempfile.new(['empty', '.csv']) }

      before do
        empty_csv.write("Clé;Catégorie (clé);Sous-catégorie (clé);Catégorie acheteur;Sous-catégorie acheteur;Nom acheteur;Description acheteur;Catégorie candidat;Sous-catégorie candidat;Nom candidat;Description candidat;Obligatoire;Source (api_name);Clé API;Type de saisie;Position;Types de marché\n")
        empty_csv.rewind
      end

      after { empty_csv.close! }

      it 'does not soft-delete existing records' do
        described_class.call(csv_file: empty_csv)
        expect(existing.reload.deleted_at).to be_nil
      end
    end

    context 'with dry_run: true' do
      subject(:result) { described_class.call(csv_file: csv_path, dry_run: true) }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'does not persist any market attributes' do
        expect { result }.not_to change(MarketAttribute, :count)
      end

      it 'does not persist any categories' do
        expect { result }.not_to change(Category, :count)
      end

      it 'returns create details' do
        expect(result.changes[:creates].size).to eq(2)
        expect(result.changes[:creates].first[:key]).to eq('test_siret')
      end

      it 'reports creation statistics' do
        expect(result.statistics[:created]).to eq(2)
      end

      context 'when updating existing records' do
        let!(:existing) do
          create(:market_attribute,
            key: 'test_siret',
            category_key: 'identite_entreprise',
            subcategory_key: 'identite_identification',
            buyer_name: 'Old name',
            input_type: :text_input)
        end

        it 'does not persist changes' do
          result
          expect(existing.reload.buyer_name).to eq('Old name')
        end

        it 'returns update details with diff' do
          expect(result.changes[:updates].size).to eq(1)
          update = result.changes[:updates].first
          expect(update[:key]).to eq('test_siret')
          expect(update[:diff]).to have_key('buyer_name')
        end
      end

      context 'with records to soft-delete' do
        let!(:orphan) do
          create(:market_attribute,
            key: 'orphan_field',
            category_key: 'identite_entreprise',
            subcategory_key: 'identite_identification')
        end

        it 'does not soft-delete records' do
          result
          expect(orphan.reload.deleted_at).to be_nil
        end

        it 'returns delete details' do
          expect(result.changes[:deletes].size).to eq(1)
          expect(result.changes[:deletes].first[:key]).to eq('orphan_field')
        end

        it 'reports soft-delete statistics' do
          expect(result.statistics[:soft_deleted]).to eq(1)
        end
      end
    end

    context 'with a wrong separator (comma instead of semicolon)' do
      let(:bad_csv) { Tempfile.new(['bad_sep', '.csv']) }

      before do
        bad_csv.write("Clé,Catégorie (clé),Nom acheteur\n")
        bad_csv.write("test_key,cat_key,Some name\n")
        bad_csv.rewind
      end

      after { bad_csv.close! }

      it 'returns failure with column count error' do
        result = described_class.call(csv_file: bad_csv)
        expect(result).not_to be_success
        expect(result.errors.first).to include('colonnes détectées')
        expect(result.errors.first).to include('point-virgule')
      end

      it 'does not create any records' do
        expect { described_class.call(csv_file: bad_csv) }.not_to change(MarketAttribute, :count)
      end
    end

    context 'with an invalid file path' do
      it 'returns failure with error message' do
        result = described_class.call(csv_file: '/nonexistent/file.csv')
        expect(result).not_to be_success
        expect(result.errors).to include('Fichier introuvable')
      end
    end

    context 'with a File object' do
      it 'accepts a File object' do
        File.open(csv_path) do |file|
          result = described_class.call(csv_file: file)
          expect(result).to be_success
          expect(result.statistics[:created]).to eq(2)
        end
      end
    end

    context 'with existing categories' do
      let!(:category) do
        create(:category, key: 'identite_entreprise', buyer_label: 'Old label', candidate_label: 'Old')
      end

      it 'updates category labels from the CSV' do
        described_class.call(csv_file: csv_path)
        category.reload
        expect(category.buyer_label).to eq('Identité entreprise')
        expect(category.candidate_label).to eq('Identity')
      end
    end
  end
end
