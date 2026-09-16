# frozen_string_literal: true

module GroupementWizardSteps
  extend ActiveSupport::Concern

  POST_APPLICATION_MODE_STEPS = %i[lot_selection_mode grouping_legal_type grouping_composition].freeze

  def application_mode_choice_required?
    FeatureFlags::Groupement.enabled? && application_mode.nil?
  end

  def grouping_legal_type_choice_required?
    return false if completed?

    FeatureFlags::Groupement.enabled? && groupement? &&
      Grouping.joins(:mandataire_market_application).exists?(legal_type: nil, market_applications: { id: })
  end

  def already_mandataire_elsewhere?
    Grouping
      .joins(:mandataire_market_application)
      .where(public_market:, market_applications: { siret: })
      .where.not(market_applications: { id: })
      .exists?
  end

  def grouping_composition_choice_required?
    return false unless FeatureFlags::Groupement.enabled? && groupement?

    grouping = mandataire_grouping
    return false if grouping.nil? || grouping.legal_type.nil?

    grouping.grouping_members.co_traitant.none?(&:invitation_sent?)
  end

  def mandataire_grouping
    Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: })
  end

  def lot_selection_mode_choice_required?
    return false if completed?
    return false unless lot_selection_mode_applicable?

    solo = solo_counterpart
    return lot_ids.empty? if solo.nil?

    solo.lot_ids.empty? || lot_ids.empty?
  end

  def lot_selection_mode_applicable?
    FeatureFlags::Groupement.enabled? && groupement? && public_market.lots.any?
  end

  def next_required_wizard_step
    return nil unless FeatureFlags::Groupement.enabled?
    return [self, :application_mode] if application_mode_choice_required?

    target = groupement_counterpart || self
    step = POST_APPLICATION_MODE_STEPS.find { |candidate| target.public_send(:"#{candidate}_choice_required?") }
    step ? [target, step] : nil
  end

  def step_after_application_mode
    target = groupement_counterpart || self
    return [target, :company_identification] unless target.groupement?
    return [target, :lot_selection_mode] if target.public_market.lots.any?

    [target, :grouping_legal_type]
  end
end
