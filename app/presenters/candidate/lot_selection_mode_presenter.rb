# frozen_string_literal: true

module Candidate
  class LotSelectionModePresenter
    include LotLabelConcern

    def initialize(market_application)
      @market_application = market_application
      @solo_application = market_application.solo? ? market_application : market_application.solo_counterpart
      @groupement_application = market_application.groupement? ? market_application : market_application.groupement_counterpart
    end

    def requires_solo_and_groupement?
      @solo_application.present?
    end

    def lots_by_type_sorted
      @lots_by_type_sorted ||= public_market.lots_by_type_sorted
    end

    def mode_for(lot)
      mode_by_lot_id.fetch(lot.id) { default_mode_for }
    end

    private

    attr_reader :market_application

    def public_market
      @public_market ||= market_application.public_market
    end

    def mode_by_lot_id
      @mode_by_lot_id ||= begin
        modes = {}
        @solo_application&.lot_ids&.each { |id| modes[id] = 'solo' }
        @groupement_application.lot_ids.each { |id| modes[id] = 'groupement' }
        modes
      end
    end

    def default_mode_for
      mode_by_lot_id.any? ? 'none' : 'groupement'
    end
  end
end
