# frozen_string_literal: true

class GroupingInvitationMailerPreview < ActionMailer::Preview
  def invitation
    grouping_member = GroupingMember.joins(:grouping).where.not(role: :mandataire).order(id: :desc).first ||
                      raise('No co_traitant GroupingMember found to preview this mailer. Seed some grouping data first.')
    url = 'http://localhost:3000/candidate/grouping_invitations/abc123'

    GroupingInvitationMailer.invitation(grouping_member, url)
  end
end
