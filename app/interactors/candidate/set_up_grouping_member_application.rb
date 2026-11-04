# frozen_string_literal: true

module Candidate
  class SetUpGroupingMemberApplication < ApplicationInteractor
    delegate :grouping_member, to: :context

    def call
      context.market_application = grouping_member.market_application || create_market_application
      context.email = grouping_member.email
      context.reconnection = false
    end

    private

    def create_market_application
      grouping_member.with_lock { locked_market_application }
    end

    def locked_market_application
      return grouping_member.market_application if grouping_member.market_application

      application = MarketApplication.new(
        public_market: grouping_member.public_market,
        siret: grouping_member.siret,
        application_mode: :groupement
      )

      return context.fail!(errors: errors_from(application)) unless application.save

      grouping_member.update!(market_application: application)
      application
    end

    def errors_from(record)
      record.errors.each_with_object({}) do |error, hash|
        (hash[error.attribute] ||= []) << error.message
      end
    end
  end
end
