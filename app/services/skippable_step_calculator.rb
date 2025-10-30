class SkippableStepCalculator < ApplicationService
  EXCLUSION_STEPS = %w[
    motifs_exclusion_condamnations_penales
    motifs_exclusion_sociaux_declarations
    motifs_exclusion_fiscaux_taxes_impots
    motifs_exclusion_appreciation_acheteur_discretionnaire
  ].freeze

  HIDDEN_FIELD_TYPES = %w[
    MarketAttributeResponse::RadioWithFileAndText
    MarketAttributeResponse::RadioWithJustificationOptional
  ].freeze

  def initialize(market_application, step_name)
    @market_application = market_application
    @step_name = step_name.to_s
  end

  def call
    return false unless EXCLUSION_STEPS.include?(@step_name)
    return false if @market_application.subject_to_prohibition.nil?
    return false if @market_application.subject_to_prohibition == true

    !visible_fields?
  end

  private

  def visible_fields?
    presenter = MarketApplicationPresenter.new(@market_application)
    responses = presenter.responses_grouped_by_subcategory(
      presenter.parent_category_for(@step_name)
    )[@step_name]

    return true if responses.blank?

    responses.any? do |response|
      response.auto? || HIDDEN_FIELD_TYPES.exclude?(response.type)
    end
  end
end
