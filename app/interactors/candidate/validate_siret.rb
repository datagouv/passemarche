# frozen_string_literal: true

module Candidate
  class ValidateSiret < ApplicationInteractor
    delegate :siret, to: :context

    def call
      return if SiretValidator.valid?(siret)

      context.fail!(errors: { siret: [I18n.t('errors.messages.invalid')] })
    end
  end
end
