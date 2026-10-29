# frozen_string_literal: true

class Candidate::DashboardPreviewData
  class << self
    def public_market(deadline: 1.month.from_now)
      PublicMarket.new(name: 'Rénovation énergétique du groupe scolaire Jean-Jaurès', buyer_name: 'Ville de Pessac',
        deadline:)
    end

    def individual(public_market:, completed_at: nil)
      market_application(public_market:, identifier: 'preview-dashboard-individual', application_mode: :solo,
        completed_at:)
    end

    def mandataire(public_market:, submitted_at: nil)
      application = market_application(public_market:, identifier: 'preview-dashboard-mandataire',
        application_mode: :groupement)
      application.grouping_member = GroupingMember.new(role: :mandataire, grouping: grouping(submitted_at:))
      application
    end

    def co_traitant(public_market:, completed_at: nil, submitted_at: nil)
      application = market_application(public_market:, identifier: 'preview-dashboard-co-traitant',
        application_mode: :groupement, completed_at:)
      application.grouping_member = GroupingMember.new(role: :co_traitant, grouping: grouping(submitted_at:))
      application
    end

    private

    def market_application(public_market:, identifier:, application_mode:, completed_at: nil)
      MarketApplication.new(public_market:, identifier:, application_mode:, completed_at:,
        updated_at: Time.zone.local(2026, 10, 20, 10))
    end

    def grouping(submitted_at:)
      grouping = Grouping.new(submitted_at:)
      grouping.mandataire_grouping_member = GroupingMember.new(role: :mandataire, siret: '41816609600069',
        company_name: 'Menuiseries Loire')
      grouping
    end
  end
end
