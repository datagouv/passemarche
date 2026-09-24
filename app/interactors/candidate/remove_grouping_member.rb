# frozen_string_literal: true

module Candidate
  class RemoveGroupingMember < ApplicationInteractor
    delegate :grouping, :grouping_member_id, to: :context

    def call
      context.grouping_member = find_member
      return fail_not_found unless context.grouping_member

      destroy_member_and_application
    end

    private

    def destroy_member_and_application
      ActiveRecord::Base.transaction do
        context.grouping_member.market_application&.lock!
        context.grouping_member.lock!

        fail_already_completed unless context.grouping_member.destroy
      end
    end

    def find_member
      grouping.grouping_members.co_traitant.find_by(id: grouping_member_id)
    end

    def fail_not_found
      context.not_found = true
      context.fail!(errors: { grouping_member: [I18n.t('candidate.validations.grouping_member_not_found')] })
    end

    def fail_already_completed
      context.fail!(errors: { grouping_member: [I18n.t('candidate.validations.grouping_member_already_completed')] })
    end
  end
end
