# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ExportDashboardStatistics, type: :interactor do
  subject(:result) { described_class.call(statistics:, editor:) }

  let(:editor) { nil }
  let(:statistics) do
    {
      editors_total: 5,
      editors_active: 3,
      markets_total: 10,
      markets_completed: 7,
      markets_active: 3,
      applications_total: 25,
      applications_completed: 20,
      documents_transmitted: 100,
      unique_companies: 15,
      unique_buyers: 8,
      avg_completion_time_seconds: 900.0,
      auto_fill_rate: 0.75
    }
  end

  describe '.call' do
    describe 'csv_data' do
      it 'generates valid CSV with semicolon separator' do
        csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
        expect(csv.headers).to eq(['Métrique', 'Valeur', "Date d'export", 'Éditeur'])
      end

      context 'without editor filter' do
        it 'includes all 12 metrics' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          expect(csv.size).to eq(12)
        end

        it 'includes editor statistics' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          metrics = csv.map { |row| row['Métrique'] }

          expect(metrics).to include('Éditeurs configurés')
          expect(metrics).to include('Éditeurs actifs et autorisés')
        end
      end

      context 'with editor filter' do
        let(:editor) { build(:editor, name: 'Mon Éditeur') }

        it 'excludes editor statistics (10 metrics)' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          expect(csv.size).to eq(10)
        end

        it 'does not include global editor statistics' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          metrics = csv.map { |row| row['Métrique'] }

          expect(metrics).not_to include('Éditeurs configurés')
          expect(metrics).not_to include('Éditeurs actifs et autorisés')
        end

        it 'still includes market statistics' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          metrics = csv.map { |row| row['Métrique'] }

          expect(metrics).to include('Marchés créés')
          expect(metrics).to include('Candidatures complétées')
        end
      end

      it 'includes correct metric labels' do
        csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
        metrics = csv.map { |row| row['Métrique'] }

        expect(metrics).to include('Marchés créés')
        expect(metrics).to include('Candidatures complétées')
      end

      it 'includes correct values for numeric statistics' do
        csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
        editors_row = csv.find { |row| row['Métrique'] == 'Éditeurs configurés' }

        expect(editors_row['Valeur']).to eq('5')
      end

      it 'formats completion time correctly' do
        csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
        time_row = csv.find { |row| row['Métrique'] == 'Temps moyen de remplissage' }

        expect(time_row['Valeur']).to eq('0h15min')
      end

      it 'formats auto-fill rate as percentage' do
        csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
        rate_row = csv.find { |row| row['Métrique'] == 'Taux de remplissage automatique' }

        expect(rate_row['Valeur']).to eq('75.0%')
      end

      it 'includes export date in each row' do
        csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
        dates = csv.map { |row| row["Date d'export"] }.uniq

        expect(dates).to eq([I18n.l(Date.current, format: :default)])
      end

      context 'without editor filter' do
        it 'includes "Tous" as editor name' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          editors = csv.map { |row| row['Éditeur'] }.uniq

          expect(editors).to eq(['Tous'])
        end
      end

      context 'with editor filter' do
        let(:editor) { build(:editor, name: 'Mon Éditeur Test') }

        it 'includes editor name in each row' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          editors = csv.map { |row| row['Éditeur'] }.uniq

          expect(editors).to eq(['Mon Éditeur Test'])
        end
      end

      context 'with nil completion time' do
        let(:statistics) { super().merge(avg_completion_time_seconds: nil) }

        it 'displays N/A for completion time' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          time_row = csv.find { |row| row['Métrique'] == 'Temps moyen de remplissage' }

          expect(time_row['Valeur']).to eq('N/A')
        end
      end

      context 'with nil auto-fill rate' do
        let(:statistics) { super().merge(auto_fill_rate: nil) }

        it 'displays N/A for auto-fill rate' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          rate_row = csv.find { |row| row['Métrique'] == 'Taux de remplissage automatique' }

          expect(rate_row['Valeur']).to eq('N/A')
        end
      end

      context 'with hours in completion time' do
        let(:statistics) { super().merge(avg_completion_time_seconds: 7320.0) }

        it 'formats as hours and minutes' do
          csv = CSV.parse(result.csv_data, col_sep: ';', headers: true)
          time_row = csv.find { |row| row['Métrique'] == 'Temps moyen de remplissage' }

          expect(time_row['Valeur']).to eq('2h2min')
        end
      end
    end

    describe 'filename' do
      context 'without editor filter' do
        it 'generates filename with global suffix' do
          expect(result.filename).to eq("statistiques-passe-marche-global-#{Date.current}.csv")
        end
      end

      context 'with editor filter' do
        let(:editor) { build(:editor, name: 'Mon Éditeur Test') }

        it 'generates filename with parameterized editor name' do
          expect(result.filename).to eq("statistiques-passe-marche-mon-editeur-test-#{Date.current}.csv")
        end
      end

      context 'with editor name containing special characters' do
        let(:editor) { build(:editor, name: 'Éditeur Spécial & Co.') }

        it 'parameterizes the editor name correctly' do
          expect(result.filename).to eq("statistiques-passe-marche-editeur-special-co-#{Date.current}.csv")
        end
      end
    end
  end
end
