# frozen_string_literal: true

module Candidate
  class ConfirmGroupingComposition < ApplicationInteractor
    delegate :grouping, to: :context

    def call
      pending_members = grouping.grouping_members.co_traitant.reject(&:invitation_sent?)
      return fail_no_co_traitant if grouping.grouping_members.co_traitant.none?

      pending_members.each { |member| invite(member) }
    end

    private

    def invite(member)
      member.update!(invitation_token: SecureRandom.urlsafe_base64(32), invitation_token_created_at: Time.current)
      GroupingInvitationMailer.invitation(member, invitation_url(member)).deliver_later
    end

    def invitation_url(member)
      Rails.application.routes.url_helpers.candidate_grouping_invitation_url(member.invitation_token)
    end

    def fail_no_co_traitant
      context.fail!(errors: { grouping: [I18n.t('candidate.validations.no_co_traitant')] })
    end
  end
end
