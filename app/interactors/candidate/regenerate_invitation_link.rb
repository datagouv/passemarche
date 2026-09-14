# frozen_string_literal: true

module Candidate
  class RegenerateInvitationLink < ApplicationInteractor
    delegate :grouping_member, :notify, to: :context

    def call
      grouping_member.update!(invitation_token: SecureRandom.urlsafe_base64(32), invitation_token_created_at: Time.current)
      GroupingInvitationMailer.invitation(grouping_member, invitation_url).deliver_later if notify
    end

    private

    def invitation_url
      Rails.application.routes.url_helpers.candidate_grouping_invitation_url(grouping_member.invitation_token)
    end
  end
end
