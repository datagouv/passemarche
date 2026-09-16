# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::SetLotSelectionModes, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }
  let(:lot1) { create(:lot, public_market:) }
  let(:lot2) { create(:lot, public_market:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    context 'in mixte mode (solo and groupement counterpart exist)' do
      let!(:solo_application) { create(:market_application, public_market:, siret:, application_mode: :solo) }
      let!(:groupement_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'assigns each lot to the matching application' do
        result = described_class.call(
          market_application: solo_application,
          lot_modes: { lot1.id.to_s => 'solo', lot2.id.to_s => 'groupement' }
        )

        expect(result).to be_success
        expect(solo_application.reload.lots).to contain_exactly(lot1)
        expect(groupement_application.reload.lots).to contain_exactly(lot2)
      end

      it 'leaves a lot unassigned when its mode is none' do
        create(:lot, public_market:)

        result = described_class.call(
          market_application: solo_application,
          lot_modes: { lot1.id.to_s => 'solo', lot2.id.to_s => 'groupement' }
        )

        expect(result).to be_success
        expect(solo_application.reload.lots + groupement_application.reload.lots).to contain_exactly(lot1, lot2)
      end

      it 'replaces the previous selection on resubmission' do
        solo_application.lots << lot1
        groupement_application.lots << lot2

        result = described_class.call(
          market_application: solo_application,
          lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'solo' }
        )

        expect(result).to be_success
        expect(solo_application.reload.lots).to contain_exactly(lot2)
        expect(groupement_application.reload.lots).to contain_exactly(lot1)
      end

      it 'fails when no lot is set to solo' do
        result = described_class.call(
          market_application: solo_application,
          lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'groupement' }
        )

        expect(result).to be_failure
        expect(result.errors[:base]).to be_present
      end

      it 'fails when no lot is set to groupement' do
        result = described_class.call(
          market_application: solo_application,
          lot_modes: { lot1.id.to_s => 'solo', lot2.id.to_s => 'solo' }
        )

        expect(result).to be_failure
        expect(result.errors[:base]).to be_present
      end

      it 'does not change either application when validation fails' do
        solo_application.lots << lot1

        result = described_class.call(
          market_application: solo_application,
          lot_modes: { lot1.id.to_s => 'solo', lot2.id.to_s => 'solo' }
        )

        expect(result).to be_failure
        expect(solo_application.reload.lots).to contain_exactly(lot1)
      end
    end

    context 'in groupement-only mode (no solo counterpart)' do
      let!(:groupement_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'assigns lots set to groupement and succeeds' do
        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'none' }
        )

        expect(result).to be_success
        expect(groupement_application.reload.lots).to contain_exactly(lot1)
      end

      it 'fails when no lot is set to groupement' do
        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { lot1.id.to_s => 'none', lot2.id.to_s => 'none' }
        )

        expect(result).to be_failure
        expect(result.errors[:base]).to be_present
      end
    end

    context 'when called on a solo application with no groupement counterpart' do
      let!(:solo_application) { create(:market_application, public_market:, siret:, application_mode: :solo) }

      it 'fails instead of raising' do
        result = described_class.call(
          market_application: solo_application,
          lot_modes: { lot1.id.to_s => 'groupement' }
        )

        expect(result).to be_failure
        expect(result.errors[:base]).to be_present
      end
    end

    context 'with an unknown lot id' do
      let!(:groupement_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'fails' do
        other_market_lot = create(:lot)

        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { other_market_lot.id.to_s => 'groupement' }
        )

        expect(result).to be_failure
        expect(result.errors[:lot_ids]).to be_present
      end
    end
  end
end
