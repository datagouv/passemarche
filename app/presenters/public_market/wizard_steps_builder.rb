# frozen_string_literal: true

class PublicMarket::WizardStepsBuilder
  INITIAL_STEP = :setup
  LOT_CONFIG_STEP = :lot_config
  FORM_CONFIG_STEP = :form_config
  FINAL_STEP = :summary

  def initialize(public_market:, available_category_keys:)
    @public_market = public_market
    @available_category_keys = available_category_keys
  end

  def wizard_steps
    [INITIAL_STEP] + lot_steps + category_steps + [FINAL_STEP]
  end

  def stepper_steps
    category_steps + [FINAL_STEP]
  end

  private

  def lot_steps
    @public_market.lots.any? ? [LOT_CONFIG_STEP, FORM_CONFIG_STEP] : []
  end

  def category_steps
    @available_category_keys.map(&:to_sym)
  end
end
