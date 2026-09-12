# frozen_string_literal: true

class GroupingInvitationMailerPreview < ActionMailer::Preview
  def invitation
    public_market = PublicMarket.new(
      name: "Système d'acquisition dynamique (SAD) pour la fourniture de matériels informatiques"
    )
    grouping = Grouping.new(public_market:)
    grouping_member = GroupingMember.new(email: 'contact@menuiseries-loire.fr', siret: '80245139600027', grouping:)
    url = 'http://localhost:3000/candidate/grouping_invitations/abc123'

    GroupingInvitationMailer.invitation(grouping_member, url)
  end
end
