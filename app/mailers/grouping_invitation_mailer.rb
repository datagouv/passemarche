# frozen_string_literal: true

class GroupingInvitationMailer < ApplicationMailer
  def invitation(grouping_member, url)
    @grouping_member = grouping_member
    @url = url
    @market_name = grouping_member.grouping.public_market.name

    mail(to: @grouping_member.email, subject: I18n.t('grouping_invitation_mailer.invitation.subject'))
  end
end
