# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::GroupingDashboardPresenter do
  subject(:presenter) { described_class.new(market_application) }

  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }
  let(:market_application) { grouping.mandataire_market_application }
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
  let(:mandataire_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '#grouping' do
    it 'returns the grouping the mandataire market_application belongs to' do
      expect(presenter.grouping).to eq(grouping)
    end
  end

  describe '#members' do
    it 'orders the mandataire first' do
      create(:grouping_member, :co_traitant, grouping:)

      expect(presenter.members.first).to eq(grouping.mandataire_grouping_member)
    end

    context 'when viewing as a co_traitant' do
      it 'orders the current member first' do
        other_member = create(:grouping_member, :co_traitant, grouping:)
        current_application = create(:market_application, public_market:, application_mode: :groupement)
        current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application)
        co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

        expect(co_traitant_presenter.members.first).to eq(current_member)
        expect(co_traitant_presenter.members).to include(other_member)
      end
    end
  end

  describe '#member_actions' do
    let(:member) { create(:grouping_member, :co_traitant, grouping:, status:) }

    context 'when invited' do
      let(:status) { :invited }

      it 'offers copy link only' do
        expect(presenter.member_actions(member)).to eq([:copy_link])
      end
    end

    context 'when to_prepare' do
      let(:status) { :to_prepare }

      it 'offers copy link only' do
        expect(presenter.member_actions(member)).to eq([:copy_link])
      end
    end

    context 'when in_progress' do
      let(:status) { :in_progress }

      it 'offers copy link only' do
        expect(presenter.member_actions(member)).to eq([:copy_link])
      end
    end

    context 'when completed' do
      let(:status) { :completed }

      it 'offers copy link only' do
        expect(presenter.member_actions(member)).to eq([:copy_link])
      end
    end

    context 'for the mandataire member' do
      it 'offers prepare when to_prepare' do
        member = grouping.mandataire_grouping_member
        member.update!(status: :to_prepare)

        expect(presenter.member_actions(member)).to eq([:prepare])
      end

      it 'offers edit when in_progress' do
        member = grouping.mandataire_grouping_member
        member.update!(status: :in_progress)

        expect(presenter.member_actions(member)).to eq([:edit])
      end

      it 'offers consult when completed' do
        member = grouping.mandataire_grouping_member
        member.update!(status: :completed)

        expect(presenter.member_actions(member)).to eq([:consult])
      end
    end

    context 'when viewing as a co_traitant' do
      it 'offers prepare on its own row when to_prepare' do
        current_application = create(:market_application, public_market:, application_mode: :groupement)
        current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application,
          status: :to_prepare)
        co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

        expect(co_traitant_presenter.member_actions(current_member)).to eq([:prepare])
      end

      it 'still offers to edit its own application once transmitted to the mandataire' do
        current_application = create(:market_application, public_market:, application_mode: :groupement)
        current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application,
          status: :completed)
        co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

        expect(co_traitant_presenter.member_actions(current_member)).to eq([:edit])
      end

      it 'offers no action on other members rows' do
        current_application = create(:market_application, public_market:, application_mode: :groupement)
        current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application)
        co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

        expect(co_traitant_presenter.member_actions(grouping.mandataire_grouping_member)).to eq([])
      end
    end
  end

  describe '#member_actions once the market deadline is over' do
    before { public_market.update_column(:deadline, 1.day.ago) }

    it 'only lets a co_traitant who transmitted their form consult it' do
      current_application = create(:market_application, public_market:, application_mode: :groupement)
      current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application,
        status: :completed)
      co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

      expect(co_traitant_presenter.member_actions(current_member)).to eq([:consult])
    end

    it 'no longer offers to copy the invitation link of other members' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :invited)

      expect(presenter.member_actions(member)).to eq([])
    end
  end

  describe '#member_actions for a co_traitant who edited again after transmitting, once the grouping is locked' do
    it 'still lets them consult their form' do
      current_application = create(:market_application, :completed, public_market:, application_mode: :groupement)
      current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application,
        status: :in_progress)
      grouping.update!(submitted_at: Time.current, submission_mode: :partial)
      co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

      expect(co_traitant_presenter.member_actions(current_member)).to eq([:consult])
    end
  end

  describe '#co_traitant_lock_notice' do
    it 'is nil while the grouping can still be edited' do
      expect(presenter.co_traitant_lock_notice).to be_nil
    end

    it 'announces the transmission once the grouping is submitted' do
      grouping.update!(submitted_at: Time.current, submission_mode: :full)

      expect(presenter.co_traitant_lock_notice).to eq(key: 'co_traitant_submission_done', color: :success)
    end

    it 'announces the deadline when it passed before the grouping was submitted' do
      public_market.update_column(:deadline, 1.day.ago)

      expect(presenter.co_traitant_lock_notice).to eq(key: 'co_traitant_deadline_passed', color: :warning)
    end
  end

  describe '#member_actions once the grouping is submitted' do
    before { grouping.update!(submitted_at: Time.current, submission_mode: :partial) }

    it 'only lets a completed member consult their own application' do
      grouping.mandataire_grouping_member.update!(status: :completed)

      expect(presenter.member_actions(grouping.mandataire_grouping_member)).to eq([:consult])
    end

    it 'offers no action to a member who had not completed their application' do
      grouping.mandataire_grouping_member.update!(status: :in_progress)

      expect(presenter.member_actions(grouping.mandataire_grouping_member)).to eq([])
    end

    it 'only lets a co_traitant who transmitted their form consult it' do
      current_application = create(:market_application, public_market:, application_mode: :groupement)
      current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application,
        status: :completed)
      co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

      expect(co_traitant_presenter.member_actions(current_member)).to eq([:consult])
    end

    it 'no longer offers to copy the invitation link of other members' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :invited)

      expect(presenter.member_actions(member)).to eq([])
    end
  end

  describe '#viewing_as_co_traitant?' do
    it 'is false for the mandataire' do
      expect(presenter.viewing_as_co_traitant?).to be false
    end

    it 'is true for a co_traitant' do
      current_application = create(:market_application, public_market:, application_mode: :groupement)
      current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application)
      co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

      expect(co_traitant_presenter.viewing_as_co_traitant?).to be true
    end
  end

  describe '#member_role_label' do
    it 'labels the current member with a self marker' do
      expect(presenter.member_role_label(grouping.mandataire_grouping_member)).to eq(I18n.t('candidate.grouping_dashboard.role_self_mandataire'))
    end

    it 'labels other members without a self marker' do
      other_member = create(:grouping_member, :co_traitant, grouping:)

      expect(presenter.member_role_label(other_member)).to eq(I18n.t('candidate.grouping_dashboard.role_co_traitant'))
    end
  end

  describe '#member_status_badge_class' do
    it 'renders an in progress member with the blue info badge' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :in_progress)

      expect(presenter.member_status_badge_class(member)).to eq('fr-badge--info fr-badge--no-icon')
    end

    it 'renders a completed member with the green success badge' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :completed)

      expect(presenter.member_status_badge_class(member)).to eq('fr-badge--success fr-badge--no-icon')
    end
  end

  describe 'member status once the grouping is submitted' do
    let(:member) { create(:grouping_member, :co_traitant, grouping:, status: :in_progress) }

    before { grouping.update!(submitted_at: Time.current, submission_mode: :partial) }

    it 'labels every member as submitted' do
      expect(presenter.member_status_label(member)).to eq(I18n.t('candidate.grouping_dashboard.status_submitted'))
    end

    it 'renders every member with the green success badge' do
      expect(presenter.member_status_badge_class(member)).to eq('fr-badge--success fr-badge--no-icon')
    end
  end

  describe '#submitted?' do
    it 'delegates to the grouping' do
      grouping.update!(submitted_at: Time.current)

      expect(presenter.submitted?).to be true
    end
  end

  describe '#submittable?' do
    it 'delegates to the grouping' do
      grouping.mandataire_grouping_member.update!(status: :completed)
      create(:grouping_member, :co_traitant, grouping:, status: :completed, invitation_token_created_at: Time.current)

      expect(presenter.submittable?).to be true
    end
  end

  describe '#partially_submittable?' do
    it 'delegates to the grouping' do
      create(:grouping_member, :co_traitant, grouping:, status: :in_progress, invitation_token_created_at: Time.current)

      expect(presenter.partially_submittable?).to be true
    end
  end

  describe '#mixed_scope?' do
    it 'is false when there is no solo counterpart' do
      expect(presenter.mixed_scope?).to be false
    end

    it 'is true when a solo counterpart exists' do
      create(:market_application, public_market:, siret:, application_mode: :solo)

      expect(presenter.mixed_scope?).to be true
    end
  end

  describe '#lots' do
    it 'returns the mandataire market_application lots when viewed by the mandataire' do
      lot = create(:lot, public_market:)
      mandataire_application.lots << lot

      expect(presenter.lots).to contain_exactly(lot)
    end

    it 'returns the mandataire market_application lots when viewed by a co_traitant, not the co_traitant own lots' do
      lot = create(:lot, public_market:)
      mandataire_application.lots << lot
      current_application = create(:market_application, public_market:, application_mode: :groupement)
      current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application)
      co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

      expect(co_traitant_presenter.lots).to contain_exactly(lot)
    end
  end

  describe '#declared_lots_label' do
    context 'when the grouping legal_type is solidaire' do
      before { grouping.update!(legal_type: :solidaire) }

      it 'returns "all lots" regardless of the member declared lots' do
        member = create(:grouping_member, :co_traitant, grouping:)

        expect(presenter.declared_lots_label(member)).to eq(I18n.t('candidate.grouping_dashboard.declared_lots_all'))
      end
    end

    context 'when the grouping legal_type is conjoint' do
      before { grouping.update!(legal_type: :conjoint) }

      it 'returns "not provided" when the member has no declared lots' do
        member = create(:grouping_member, :co_traitant, grouping:, market_application: nil)

        expect(presenter.declared_lots_label(member)).to eq(I18n.t('candidate.grouping_dashboard.declared_lots_not_provided'))
      end

      it 'returns the count of declared lots when the member has declared lots' do
        lot1 = create(:lot, public_market:, name: 'Lot 1')
        lot2 = create(:lot, public_market:, name: 'Lot 2')
        member_application = create(:market_application, public_market:, application_mode: :groupement)
        create(:market_application_lot, market_application: member_application, lot: lot1)
        create(:market_application_lot, market_application: member_application, lot: lot2)
        member = create(:grouping_member, :co_traitant, grouping:, market_application: member_application)

        expect(presenter.declared_lots_label(member)).to eq(I18n.t('candidate.grouping_dashboard.lots_count', count: 2))
      end
    end
  end

  describe '#solo_counterpart' do
    it 'delegates to market_application.solo_counterpart' do
      solo_application = create(:market_application, public_market:, siret:, application_mode: :solo)

      expect(presenter.solo_counterpart).to eq(solo_application)
    end
  end
end
