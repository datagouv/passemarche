# frozen_string_literal: true

module Candidate
  class ValidateEmailFormat < ApplicationInteractor
    delegate :email, to: :context

    def call
      return if email.to_s.match?(URI::MailTo::EMAIL_REGEXP)

      context.fail!(errors: { email: [I18n.t('errors.messages.invalid')] })
    end
  end
end
