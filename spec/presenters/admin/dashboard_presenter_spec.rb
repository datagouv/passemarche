# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardPresenter do
  subject(:presenter) { described_class.new(statistics:, editor:) }

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

  describe '#scoped?' do
    context 'without editor' do
      it 'returns false' do
        expect(presenter.scoped?).to be false
      end
    end

    context 'with editor' do
      let(:editor) { build(:editor, name: 'Test Editor') }

      it 'returns true' do
        expect(presenter.scoped?).to be true
      end
    end
  end

  describe '#page_title' do
    context 'without editor' do
      it 'returns the base title' do
        expect(presenter.page_title).to eq("Suivi d'activité")
      end
    end

    context 'with editor' do
      let(:editor) { build(:editor, name: 'Mon Éditeur') }

      it 'returns the title with editor name' do
        expect(presenter.page_title).to eq("Suivi d'activité - Mon Éditeur")
      end
    end
  end

  describe '#formatted_completion_time' do
    context 'with nil completion time' do
      let(:statistics) { { avg_completion_time_seconds: nil } }

      it 'returns N/A' do
        expect(presenter.formatted_completion_time).to eq('N/A')
      end
    end

    context 'with zero completion time' do
      let(:statistics) { { avg_completion_time_seconds: 0 } }

      it 'returns N/A' do
        expect(presenter.formatted_completion_time).to eq('N/A')
      end
    end

    context 'with seconds only' do
      let(:statistics) { { avg_completion_time_seconds: 45.0 } }

      it 'returns formatted duration' do
        expect(presenter.formatted_completion_time).to eq('0h0min')
      end
    end

    context 'with minutes and seconds' do
      let(:statistics) { { avg_completion_time_seconds: 185.0 } }

      it 'returns formatted duration' do
        expect(presenter.formatted_completion_time).to eq('0h3min')
      end
    end

    context 'with exactly one minute' do
      let(:statistics) { { avg_completion_time_seconds: 60.0 } }

      it 'returns formatted duration' do
        expect(presenter.formatted_completion_time).to eq('0h1min')
      end
    end

    context 'with hours' do
      let(:statistics) { { avg_completion_time_seconds: 7320.0 } }

      it 'returns formatted hours and minutes' do
        expect(presenter.formatted_completion_time).to eq('2h2min')
      end
    end
  end

  describe '#auto_fill_percentage' do
    context 'with nil rate' do
      let(:statistics) { { auto_fill_rate: nil } }

      it 'returns N/A' do
        expect(presenter.auto_fill_percentage).to eq('N/A')
      end
    end

    context 'with zero rate' do
      let(:statistics) { { auto_fill_rate: 0.0 } }

      it 'returns 0.0%' do
        expect(presenter.auto_fill_percentage).to eq('0.0%')
      end
    end

    context 'with rate' do
      let(:statistics) { { auto_fill_rate: 0.6789 } }

      it 'returns formatted percentage with one decimal' do
        expect(presenter.auto_fill_percentage).to eq('67.9%')
      end
    end

    context 'with 100% rate' do
      let(:statistics) { { auto_fill_rate: 1.0 } }

      it 'returns 100.0%' do
        expect(presenter.auto_fill_percentage).to eq('100.0%')
      end
    end
  end

  describe '#statistics_cards' do
    it 'returns 12 cards' do
      expect(presenter.statistics_cards.size).to eq(12)
    end

    it 'returns cards with correct keys' do
      keys = presenter.statistics_cards.pluck(:key)
      expect(keys).to eq(Admin::DashboardPresenter::CARD_KEYS)
    end

    it 'returns correct values for numeric statistics' do
      cards = presenter.statistics_cards
      expect(cards.find { |c| c[:key] == :editors_total }[:value]).to eq(5)
      expect(cards.find { |c| c[:key] == :applications_completed }[:value]).to eq(20)
    end

    it 'returns formatted value for completion time' do
      cards = presenter.statistics_cards
      expect(cards.find { |c| c[:key] == :avg_completion_time }[:value]).to eq('0h15min')
    end

    it 'returns formatted value for auto fill rate' do
      cards = presenter.statistics_cards
      expect(cards.find { |c| c[:key] == :auto_fill_rate }[:value]).to eq('75.0%')
    end
  end

  describe 'with empty statistics' do
    let(:statistics) do
      {
        editors_total: 0,
        editors_active: 0,
        markets_total: 0,
        markets_completed: 0,
        markets_active: 0,
        applications_total: 0,
        applications_completed: 0,
        documents_transmitted: 0,
        unique_companies: 0,
        unique_buyers: 0,
        avg_completion_time_seconds: nil,
        auto_fill_rate: nil
      }
    end

    it 'handles zero values correctly' do
      cards = presenter.statistics_cards
      expect(cards.find { |c| c[:key] == :editors_total }[:value]).to eq(0)
      expect(cards.find { |c| c[:key] == :avg_completion_time }[:value]).to eq('N/A')
      expect(cards.find { |c| c[:key] == :auto_fill_rate }[:value]).to eq('N/A')
    end
  end
end
