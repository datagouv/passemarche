# frozen_string_literal: true

module Candidate
  class FindOrCreateUser < ApplicationInteractor
    delegate :email, to: :context

    def call
      return if context.user

      user = User.find_or_create_by_email(email)

      if user.persisted?
        context.user = user
      else
        context.fail!(errors: user.errors.full_messages)
      end
    end
  end
end
