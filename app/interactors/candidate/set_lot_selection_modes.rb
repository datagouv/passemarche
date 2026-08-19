# frozen_string_literal: true

module Candidate
  class SetLotSelectionModes < ApplicationInteractor
    delegate :market_application, :lot_modes, to: :context

    def call
      assign_applications

      return fail_groupement_application_not_found if groupement_application.blank?
      return fail_invalid_lot_ids unless valid_lot_ids?
      return fail_incomplete_selection unless selection_complete?

      ActiveRecord::Base.transaction do
        solo_application&.update!(lot_ids: solo_lot_ids)
        groupement_application.update!(lot_ids: groupement_lot_ids)
      end
    end

    private

    delegate :solo_application, :groupement_application, to: :context

    def assign_applications
      context.solo_application = market_application.solo? ? market_application : market_application.solo_counterpart
      context.groupement_application = market_application.groupement? ? market_application : market_application.groupement_counterpart
    end

    def solo_lot_ids
      lot_modes.select { |_id, mode| mode.to_s == 'solo' }.keys.map(&:to_i)
    end

    def groupement_lot_ids
      lot_modes.select { |_id, mode| mode.to_s == 'groupement' }.keys.map(&:to_i)
    end

    def selection_complete?
      return groupement_lot_ids.any? if solo_application.blank?

      solo_lot_ids.any? && groupement_lot_ids.any?
    end

    def valid_lot_ids?
      known_ids = market_application.public_market.lots.pluck(:id)
      lot_modes.keys.map(&:to_i).all? { |id| known_ids.include?(id) }
    end

    def fail_groupement_application_not_found
      context.fail!(errors: { base: [I18n.t('candidate.validations.groupement_application_not_found')] })
    end

    def fail_invalid_lot_ids
      context.fail!(errors: { lot_ids: [I18n.t('candidate.validations.lot_ids_invalid')] })
    end

    def fail_incomplete_selection
      context.fail!(errors: { base: [I18n.t('candidate.validations.lot_selection_mode_incomplete')] })
    end
  end
end
