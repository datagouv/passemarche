# frozen_string_literal: true

module Candidate
  class RemoveGroupingMember < ApplicationInteractor
    delegate :grouping, :grouping_member_id, to: :context

    def call
      context.grouping_member = find_member
      return fail_not_found unless context.grouping_member
      return fail_already_invited if context.grouping_member.invitation_sent?

      context.grouping_member.destroy
    end

    private

    def find_member
      grouping.grouping_members.co_traitant.find_by(id: grouping_member_id)
    end

    def fail_not_found
      context.fail!(errors: { grouping_member: [I18n.t('candidate.validations.grouping_member_not_found')] })
    end

    def fail_already_invited
      context.fail!(errors: { grouping_member: [I18n.t('candidate.validations.grouping_member_already_invited')] })
    end
  end
end
