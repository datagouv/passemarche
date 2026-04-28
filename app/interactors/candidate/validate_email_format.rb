# frozen_string_literal: true

module Candidate
  class ValidateEmailFormat < ApplicationInteractor
    delegate :email, to: :context

    def call
      if email.blank?
        context.fail!(errors: { email: [I18n.t('candidate.validations.email_blank')] })
      elsif !EmailValidator.valid?(email)
        context.fail!(errors: { email: [I18n.t('candidate.validations.email_invalid')] })
      end
    end
  end
end
