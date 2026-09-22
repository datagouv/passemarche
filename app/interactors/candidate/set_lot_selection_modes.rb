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
        locked_co_traitant_applications = co_traitant_applications.each(&:lock!)
        groupement_application.lock!
        fail_completed_co_traitant_application if completed_co_traitant_application_affected?(locked_co_traitant_applications)

        update_applications(locked_co_traitant_applications)
      end
    end

    private

    delegate :solo_application, :groupement_application, to: :context

    def update_applications(co_traitant_applications)
      previous_groupement_lot_ids = groupement_application.lot_ids

      solo_application&.update!(lot_ids: solo_lot_ids)
      groupement_application.update!(lot_ids: groupement_lot_ids)
      remove_lots_from_co_traitants(co_traitant_applications, previous_groupement_lot_ids - groupement_lot_ids)
    end

    def remove_lots_from_co_traitants(co_traitant_applications, removed_lot_ids)
      return if removed_lot_ids.empty?

      removed_lots = Lot.where(id: removed_lot_ids)

      co_traitant_applications.each do |co_traitant_application|
        co_traitant_application.lots.delete(removed_lots)
      end
    end

    def completed_co_traitant_application_affected?(co_traitant_applications)
      removed_lot_ids = groupement_application.lot_ids - groupement_lot_ids
      return false if removed_lot_ids.empty?

      co_traitant_applications.any? do |co_traitant_application|
        co_traitant_application.completed? && co_traitant_application.lot_ids.intersect?(removed_lot_ids)
      end
    end

    def co_traitant_applications
      grouping = groupement_application.mandataire_grouping
      return [] if grouping.nil?

      grouping.grouping_members.co_traitant.includes(:market_application).filter_map(&:market_application)
    end

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

    def fail_completed_co_traitant_application
      context.fail!(errors: { base: [I18n.t('candidate.validations.completed_co_traitant_application')] })
    end
  end
end
