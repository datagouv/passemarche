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

    context 'locking to prevent concurrent lot selection updates' do
      let!(:groupement_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      it 'locks the groupement application before reading its current lots' do
        expect(groupement_application).to receive(:lock!).ordered.and_call_original
        expect(groupement_application).to receive(:lot_ids).at_least(:once).ordered.and_call_original

        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'none' }
        )

        expect(result).to be_success
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

    context 'when a co-traitant has declared the lot being removed' do
      let!(:groupement_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }
      let(:grouping) { create(:grouping, public_market:, mandataire_market_application: groupement_application) }
      let(:co_traitant_application) do
        create(:market_application, public_market:, siret: '80245139600027', application_mode: :groupement)
      end

      before do
        allow(SiretValidator).to receive(:valid?).and_return(true)
        groupement_application.lots << [lot1, lot2]
        co_traitant_application.lots << lot1
        create(:grouping_member, :co_traitant, grouping:, market_application: co_traitant_application,
          siret: co_traitant_application.siret)
      end

      it 'removes the lot from the co-traitant application when unselected' do
        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { lot1.id.to_s => 'none', lot2.id.to_s => 'groupement' }
        )

        expect(result).to be_success
        expect(co_traitant_application.reload.lots).to be_empty
      end

      it 'leaves the co-traitant application untouched when the lot stays in groupement mode' do
        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'groupement' }
        )

        expect(result).to be_success
        expect(co_traitant_application.reload.lots).to contain_exactly(lot1)
      end

      context 'when the co-traitant application is already completed' do
        before { co_traitant_application.complete! }

        it 'fails instead of silently dropping the lot' do
          result = described_class.call(
            market_application: groupement_application,
            lot_modes: { lot1.id.to_s => 'none', lot2.id.to_s => 'groupement' }
          )

          expect(result).to be_failure
          expect(result.errors[:base]).to be_present
          expect(co_traitant_application.reload.lots).to contain_exactly(lot1)
        end

        it 'succeeds when the completed co-traitant is not affected by the removal' do
          groupement_application.lots << (lot3 = create(:lot, public_market:))

          result = described_class.call(
            market_application: groupement_application,
            lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'groupement', lot3.id.to_s => 'none' }
          )

          expect(result).to be_success
          expect(co_traitant_application.reload.lots).to contain_exactly(lot1)
        end
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

    context 'when the mandataire has already transmitted its part' do
      let!(:groupement_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }
      let(:grouping) { create(:grouping, public_market:, mandataire_market_application: groupement_application) }

      before do
        groupement_application.lots << lot1
        groupement_application.complete!
        grouping.mandataire_grouping_member.mark_completed!
      end

      it 'moves the mandataire back to in progress when the lots change' do
        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'groupement' }
        )

        expect(result).to be_success
        expect(grouping.mandataire_grouping_member.reload).to be_status_in_progress
      end

      it 'refuses the change once the grouping has been submitted' do
        grouping.update!(submitted_at: Time.current, submission_mode: :partial)

        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { lot1.id.to_s => 'none', lot2.id.to_s => 'groupement' }
        )

        expect(result).to be_failure
        expect(result.errors[:base]).to eq([I18n.t('candidate.market_applications.grouping_locked_error')])
        expect(groupement_application.reload.lots).to contain_exactly(lot1)
        expect(grouping.mandataire_grouping_member.reload).to be_status_completed
      end
    end

    context 'when a lot type leaves the groupement' do
      let(:public_market) { create(:public_market, :completed, :multi_type, editor:) }
      let(:works_lot) { public_market.lots.find_by!(name: 'Gros œuvre') }
      let(:services_lot) { public_market.lots.find_by!(name: 'Prestations SI') }
      let(:works_attribute) do
        create(:market_attribute, public_markets: [public_market], market_types: [MarketType.find_by!(code: 'works')])
      end
      let!(:groupement_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }
      let(:grouping) do
        create(:grouping, public_market:, mandataire_market_application: groupement_application, legal_type: :solidaire)
      end
      let(:co_traitant_application) do
        create(:market_application, public_market:, siret: '80245139600027', application_mode: :groupement)
      end

      before do
        groupement_application.lots << [works_lot, services_lot]
        create(:grouping_member, :co_traitant, grouping:, market_application: co_traitant_application,
          siret: co_traitant_application.siret)
        [groupement_application, co_traitant_application].each do |application|
          MarketAttributeResponse.build_for_attribute(works_attribute, market_application: application).save!
        end
      end

      it 'destroys the responses to the pieces of that type for the mandataire and the solidaire co-traitants' do
        result = described_class.call(
          market_application: groupement_application,
          lot_modes: { works_lot.id.to_s => 'none', services_lot.id.to_s => 'groupement' }
        )

        expect(result).to be_success
        expect(groupement_application.market_attribute_responses.reload).to be_empty
        expect(co_traitant_application.market_attribute_responses.reload).to be_empty
      end

      it 'keeps the responses when the lot type stays in the groupement' do
        described_class.call(
          market_application: groupement_application,
          lot_modes: { works_lot.id.to_s => 'groupement', services_lot.id.to_s => 'none' }
        )

        expect(co_traitant_application.market_attribute_responses.reload.map(&:market_attribute))
          .to contain_exactly(works_attribute)
      end
    end
  end
end
