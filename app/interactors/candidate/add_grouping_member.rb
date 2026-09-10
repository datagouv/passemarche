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
      return context.fail!(errors: errors_from(member)) unless member.save

      ResolveGroupingMemberCompanyNameJob.perform_later(member.id)
      context.grouping_member = member
    end

    def errors_from(record)
      record.errors.each_with_object({}) do |error, hash|
        (hash[error.attribute] ||= []) << error.message
      end
    end
  end
end
