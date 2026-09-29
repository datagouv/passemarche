# frozen_string_literal: true

class Grouping::PreviewData
  MANDATAIRE_SIRET = '73282932000074'
  CO_TRAITANT_SIRET = '35600000000048'

  class << self
    def grouping
      ::Grouping.find_or_create_by!(public_market:, legal_type: :conjoint_mandataire_solidaire) do |g|
        g.grouping_members.build(role: :mandataire, siret: MANDATAIRE_SIRET, email: 'mandataire@example.com',
          company_name: 'Menuiseries Loire', market_application: mandataire_market_application, status: :in_progress)
      end
    end

    def mandataire_market_application
      MarketApplication.find_or_create_by!(identifier: 'preview-grouping-mandataire') do |application|
        application.public_market = public_market
        application.siret = MANDATAIRE_SIRET
        application.attests_no_exclusion_motifs = false
      end
    end

    def co_traitant_member
      grouping.grouping_members.co_traitant.first || grouping.grouping_members.create!(
        role: :co_traitant,
        siret: CO_TRAITANT_SIRET,
        email: 'co-traitant@example.com',
        company_name: 'Charpentes Dauphiné',
        status: :in_progress,
        market_application: co_traitant_market_application
      )
    end

    def co_traitant_market_application
      MarketApplication.find_or_create_by!(identifier: 'preview-grouping-co-traitant') do |application|
        application.public_market = public_market
        application.siret = CO_TRAITANT_SIRET
        application.attests_no_exclusion_motifs = false
      end
    end

    def public_market
      PublicMarket.find_or_create_by!(identifier: 'preview-grouping-market') do |market|
        market.editor = editor
        market.name = 'Rénovation de la toiture du gymnase municipal'
        market.deadline = 1.month.from_now
        market.siret = MANDATAIRE_SIRET
        market.completed_at = Time.zone.now
        market.sync_status = :sync_completed
        market.market_type_codes = [MarketType.find_or_create_by(code: 'works', deleted_at: nil).code]
      end
    end

    def editor
      Editor.find_or_create_by!(name: 'Preview Editor')
    end
  end
end
