# frozen_string_literal: true

module Candidate
  class ValidateSiret < ApplicationInteractor
    delegate :siret, to: :context

    def call
      if siret.blank?
        context.fail!(errors: { siret: [I18n.t('candidate.validations.siret_blank')] })
      elsif !SiretValidator.valid?(siret)
        context.fail!(errors: { siret: [I18n.t('candidate.validations.siret_invalid')] })
      end
    end
  end
end
