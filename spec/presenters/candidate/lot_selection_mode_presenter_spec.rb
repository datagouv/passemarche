# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::LotSelectionModePresenter do
  subject(:presenter) { described_class.new(market_application) }

  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }
  let(:lot1) { create(:lot, public_market:) }
  let(:lot2) { create(:lot, public_market:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    lot1
    lot2
  end

  describe '#requires_solo_and_groupement?' do
    context 'when a solo counterpart exists (mixte mode)' do
      let!(:solo_application) { create(:market_application, public_market:, siret:, application_mode: :solo) }
      let(:market_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'returns true' do
        expect(presenter.requires_solo_and_groupement?).to be true
      end
    end

    context 'when no solo counterpart exists (groupement only)' do
      let(:market_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'returns false' do
        expect(presenter.requires_solo_and_groupement?).to be false
      end
    end
  end

  describe '#mode_for' do
    context 'in mixte mode' do
      let!(:solo_application) { create(:market_application, public_market:, siret:, application_mode: :solo) }
      let(:market_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'defaults to groupement when no lot has been assigned yet' do
        expect(presenter.mode_for(lot1)).to eq('groupement')
        expect(presenter.mode_for(lot2)).to eq('groupement')
      end

      it 'returns solo for a lot assigned to the solo application' do
        solo_application.lots << lot1

        expect(presenter.mode_for(lot1)).to eq('solo')
      end

      it 'returns groupement for a lot assigned to the groupement application' do
        market_application.lots << lot1

        expect(presenter.mode_for(lot1)).to eq('groupement')
      end

      it 'returns none for a lot assigned to neither once a selection exists' do
        solo_application.lots << lot1

        expect(presenter.mode_for(lot2)).to eq('none')
      end
    end

    context 'in groupement-only mode' do
      let(:market_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'defaults to groupement when no lot has been assigned yet' do
        expect(presenter.mode_for(lot1)).to eq('groupement')
      end

      it 'returns none for a lot left unassigned once a selection exists' do
        market_application.lots << lot1

        expect(presenter.mode_for(lot2)).to eq('none')
      end
    end
  end

  describe '#lots_by_type_sorted' do
    let(:market_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

    it 'groups the public market lots by their effective market type' do
      grouped = presenter.lots_by_type_sorted

      expect(grouped.values.flatten).to contain_exactly(lot1, lot2)
    end
  end
end
