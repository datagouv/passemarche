# frozen_string_literal: true

class GroupingMemberRemovalMailer < ApplicationMailer
  def removed(removal)
    removed_member = removal.reify
    grouping = removed_member.grouping
    return if grouping.nil?

    @market_name = grouping.public_market.name
    mandataire = grouping.mandataire_grouping_member
    @mandataire_name = mandataire.company_name.presence || mandataire.siret

    mail(to: removed_member.email, subject: I18n.t('grouping_member_removal_mailer.removed.subject'))
  end
end
