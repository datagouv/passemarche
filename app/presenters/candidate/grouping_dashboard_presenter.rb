# frozen_string_literal: true

module Candidate
  class GroupingDashboardPresenter
    def initialize(market_application)
      @market_application = market_application
    end

    def grouping
      @grouping ||= market_application.mandataire_grouping
    end

    def members
      grouping.grouping_members.includes(market_application: :lots).order(:role)
    end

    def member_actions(member)
      return mandataire_actions(member) if member.mandataire?

      co_traitant_actions(member)
    end

    def submission_ready?
      grouping.all_members_completed?
    end

    def partial_submission_available?
      grouping.any_member_started?
    end

    def mixed_scope?
      solo_counterpart.present?
    end

    delegate :solo_counterpart, to: :market_application

    def declared_lots_label(member)
      return I18n.t('candidate.grouping_dashboard.declared_lots_all') if grouping.legal_type_solidaire?

      count = member.declared_lots.count
      return I18n.t('candidate.grouping_dashboard.declared_lots_not_provided') if count.zero?

      I18n.t('candidate.grouping_dashboard.lots_count', count:)
    end

    private

    attr_reader :market_application

    def co_traitant_actions(member)
      return %i[relaunch copy_link] if member.status_invited?
      return %i[consult copy_link] if member.status_completed?

      %i[edit copy_link]
    end

    def mandataire_actions(member)
      return [:prepare] if member.status_invited? || member.status_to_prepare?
      return [:consult] if member.status_completed?

      [:edit]
    end
  end
end
