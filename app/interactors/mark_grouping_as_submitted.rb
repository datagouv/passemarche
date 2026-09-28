# frozen_string_literal: true

class MarkGroupingAsSubmitted < ApplicationInteractor
  delegate :grouping, :submission_mode, to: :context

  def call
    validate_submission_mode
    validate_not_already_submitted
    validate_market_still_open
    validate_submittable_for_mode

    grouping.with_lock do
      context.fail!(message: 'Groupement déjà soumis') if grouping.submitted?

      grouping.submit!(mode: submission_mode)
    end
  end

  private

  def validate_submission_mode
    context.fail!(message: 'Mode de soumission invalide') unless %i[full partial].include?(submission_mode.to_s.to_sym)
  end

  def validate_not_already_submitted
    context.fail!(message: 'Groupement déjà soumis') if grouping.submitted?
  end

  def validate_market_still_open
    context.fail!(message: 'Le marché est clos') unless grouping.public_market.open?
  end

  def validate_submittable_for_mode
    context.fail!(message: submission_error_message) unless submittable_for_mode?
  end

  def submittable_for_mode?
    submission_mode.to_sym == :full ? grouping.submittable? : grouping.partially_submittable?
  end

  def submission_error_message
    submission_mode.to_sym == :full ? 'Soumission complète impossible' : 'Soumission partielle impossible'
  end
end
