# frozen_string_literal: true

module Candidate
  class ValidateSiret < ApplicationInteractor
    delegate :siret, to: :context

    def call
      return if SiretValidationService.call(siret)

      context.fail!(errors: { siret: [I18n.t('errors.messages.invalid')] })
    end
  end
end
