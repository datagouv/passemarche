# frozen_string_literal: true

module Candidate
  class DashboardApplicationPresenter
    KIND_ICON_CLASSES = {
      mandataire: 'fr-icon-team-fill',
      co_traitant: 'fr-icon-team-fill',
      individual: 'fr-icon-user-fill'
    }.freeze
    STATUS_BADGE_CLASSES = {
      in_progress: 'fr-badge--info',
      sent_to_mandataire: 'fr-badge--success',
      submitted: 'fr-badge--success',
      deadline_passed: 'fr-badge--warning'
    }.freeze

    attr_reader :market_application

    delegate :identifier, :updated_at, :lots, to: :market_application

    def self.status_counts(market_applications)
      statuses = market_applications.includes(:public_market, grouping_member: :grouping).map do |market_application|
        new(market_application, public_market: market_application.public_market).status
      end

      { in_progress: statuses.count(:in_progress), completed: statuses.count { |status| status != :in_progress } }
    end

    def initialize(market_application, public_market:)
      @market_application = market_application
      @public_market = public_market
    end

    def kind
      @kind ||= if market_application.co_traitant_of_grouping?
                  :co_traitant
                elsif market_application.groupement?
                  :mandataire
                else
                  :individual
                end
    end

    def show_kind?
      FeatureFlags::Groupement.enabled?
    end

    def kind_label
      I18n.t("candidate.dashboard.application.kind.#{kind}")
    end

    def kind_icon_class
      KIND_ICON_CLASSES.fetch(kind)
    end

    def position
      KIND_ICON_CLASSES.keys.index(kind)
    end

    def mandataire_label
      return unless kind == :co_traitant

      mandataire = grouping.mandataire_grouping_member
      I18n.t('candidate.dashboard.application.mandataire', name: mandataire.company_name.presence || mandataire.siret)
    end

    def status
      @status ||= if submitted_to_platform?
                    :submitted
                  elsif kind == :co_traitant && market_application.completed?
                    :sent_to_mandataire
                  elsif !public_market.open?
                    :deadline_passed
                  else
                    :in_progress
                  end
    end

    def status_label
      I18n.t("candidate.dashboard.application.status.#{status}")
    end

    def status_badge_class
      STATUS_BADGE_CLASSES.fetch(status)
    end

    def dated_on_label
      date = status_date
      return I18n.t("candidate.dashboard.application.#{status}_on", date: format_date(date)) if date

      I18n.t('candidate.dashboard.application.modified_on', date: format_date(updated_at))
    end

    def dated_on_icon_class
      status_date ? 'fr-icon-calendar-line' : 'fr-icon-edit-line'
    end

    def actions
      case kind
      when :mandataire then %i[follow_up]
      when :co_traitant then co_traitant_actions
      else individual_actions
      end
    end

    private

    attr_reader :public_market

    def grouping
      market_application.grouping_member&.grouping
    end

    def submitted_to_platform?
      grouping ? grouping.submitted? : market_application.completed?
    end

    def status_date
      case status
      when :submitted then grouping ? grouping.submitted_at : market_application.completed_at
      when :sent_to_mandataire then market_application.completed_at
      end
    end

    def format_date(date)
      I18n.l(date.to_date, format: :day_month_year)
    end

    def co_traitant_actions
      return %i[edit] if status == :in_progress

      market_application.completed? ? %i[view] : []
    end

    def individual_actions
      case status
      when :submitted then %i[view]
      when :deadline_passed then %i[delete]
      else %i[delete edit]
      end
    end
  end
end
