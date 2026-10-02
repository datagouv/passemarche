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

      it 'offers no action on other members rows' do
        current_application = create(:market_application, public_market:, application_mode: :groupement)
        current_member = create(:grouping_member, :co_traitant, grouping:, market_application: current_application)
        co_traitant_presenter = described_class.new(current_application, grouping:, current_member:)

        expect(co_traitant_presenter.member_actions(grouping.mandataire_grouping_member)).to eq([])
      end
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
