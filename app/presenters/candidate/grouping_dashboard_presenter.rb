# frozen_string_literal: true

module Candidate
  class GroupingDashboardPresenter
    OWN_ACTIONS = { invited: [:prepare], to_prepare: [:prepare], in_progress: [:edit], completed: [:consult] }.freeze
    OTHER_MEMBER_ACTIONS_BY_VIEWER = {
      mandataire: %i[copy_link],
      co_traitant: []
    }.freeze

    def initialize(market_application, grouping: nil, current_member: nil)
      @market_application = market_application
      @grouping = grouping
      @current_member = current_member
    end

    def grouping
      @grouping ||= market_application.mandataire_grouping
    end

    def current_member
      @current_member ||= grouping.mandataire_grouping_member
    end

    def members
      grouping.grouping_members.includes(market_application: :lots).order(:role).sort_by { |member| member == current_member ? 0 : 1 }
    end

    def member_actions(member)
      return OWN_ACTIONS.fetch(member.status.to_sym) if member == current_member

      OTHER_MEMBER_ACTIONS_BY_VIEWER.fetch(current_member.role.to_sym)
    end

    def viewing_as_co_traitant?
      current_member.co_traitant?
    end

    delegate :submitted?, :submittable?, :partially_submittable?, to: :grouping

    def mixed_scope?
      solo_counterpart.present?
    end

    delegate :solo_counterpart, to: :market_application
    delegate :public_market, :identifier, to: :market_application

    def lots
      grouping.mandataire_market_application.lots.ordered.includes(:market_type, :platform_market_type)
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
      return I18n.t("candidate.grouping_dashboard.role_self_#{member.role}") if member == current_member

      I18n.t("candidate.grouping_dashboard.role_#{member.role}")
    end

    def member_role_badge_class(member)
      return 'fr-badge--new fr-badge--no-icon' if member == current_member

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
