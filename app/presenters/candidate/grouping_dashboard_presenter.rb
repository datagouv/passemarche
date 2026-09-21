# frozen_string_literal: true

module Candidate
  class GroupingDashboardPresenter
    MEMBER_ACTIONS = {
      mandataire: { invited: [:prepare], to_prepare: [:prepare], in_progress: [:edit], completed: [:consult] },
      co_traitant: {
        invited: %i[relaunch copy_link],
        to_prepare: %i[relaunch copy_link],
        in_progress: %i[relaunch copy_link],
        completed: %i[copy_link]
      }
    }.freeze

    def initialize(market_application, grouping: nil)
      @market_application = market_application
      @grouping = grouping
    end

    def grouping
      @grouping ||= market_application.mandataire_grouping
    end

    def members
      grouping.grouping_members.includes(market_application: :lots).order(:role)
    end

    def member_actions(member)
      MEMBER_ACTIONS.dig(member.mandataire? ? :mandataire : :co_traitant, member.status.to_sym)
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
    delegate :public_market, :identifier, to: :market_application

    def lots
      market_application.lots.ordered
    end

    def declared_lots_label(member)
      return I18n.t('candidate.grouping_dashboard.declared_lots_all') if grouping.legal_type_solidaire?

      count = member.declared_lots.size
      return I18n.t('candidate.grouping_dashboard.declared_lots_not_provided') if count.zero?

      I18n.t('candidate.grouping_dashboard.lots_count', count:)
    end

    def member_display_name(member)
      member.company_name.presence || member.siret
    end

    def member_role_label(member)
      I18n.t("candidate.grouping_dashboard.role_#{member.role}")
    end

    def member_role_badge_class(member)
      'fr-badge--info fr-badge--no-icon' if member.mandataire?
    end

    def member_status_label(member)
      I18n.t("candidate.grouping_dashboard.status_#{member.status}")
    end

    def member_status_badge_class(member)
      'fr-badge--success fr-badge--no-icon' if member.status_completed?
    end

    def member_application_identifier(member)
      member.market_application.identifier
    end

    def member_invitation_sent?(member)
      member.invitation_sent?
    end

    def member_invitation_token(member)
      member.invitation_token
    end

    private

    attr_reader :market_application
  end
end
