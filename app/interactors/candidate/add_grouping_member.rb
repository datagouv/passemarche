# frozen_string_literal: true

module Candidate
  class AddGroupingMember < ApplicationInteractor
    delegate :grouping, :siret, :email, to: :context

    def call
      create_member
    end

    private

    def create_member
      member = grouping.grouping_members.new(role: :co_traitant, siret:, email:)
      return context.fail!(errors: errors_from(member)) unless member.valid?

      member.company_name = fetch_company_name
      save_member(member)
    end

    def save_member(member)
      return context.grouping_member = member if member.save

      context.fail!(errors: errors_from(member))
    end

    def fetch_company_name
      result = FetchRaisonSociale.call(siret:)
      result.raison_sociale if result.success?
    rescue StandardError => e
      Sentry.capture_exception(e)
      nil
    end

    def errors_from(record)
      record.errors.each_with_object({}) do |error, hash|
        (hash[error.attribute] ||= []) << error.message
      end
    end
  end
end
