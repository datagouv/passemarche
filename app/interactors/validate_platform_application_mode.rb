# frozen_string_literal: true

class ValidatePlatformApplicationMode < ApplicationInteractor
  PLATFORM_APPLICATION_MODES = %w[solo groupement].freeze

  def call
    return unless context.to_h.key?(:lot_ids)
    return fail_invalid_mode unless PLATFORM_APPLICATION_MODES.include?(context.platform_application_mode.to_s)

    context.application_mode = :solo if context.platform_application_mode.to_s == 'solo'
  end

  private

  def fail_invalid_mode
    context.fail!(errors: { application_mode: [I18n.t('api.errors.platform_application_mode_invalid')] })
  end
end
