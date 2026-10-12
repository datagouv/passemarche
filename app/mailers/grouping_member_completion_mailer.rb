# frozen_string_literal: true

class GroupingMemberCompletionMailer < ApplicationMailer
  def completed(grouping_member, mandataire_email, dashboard_url)
    @dashboard_url = dashboard_url
    @market_name = grouping_member.public_market.name
    @co_traitant_name = grouping_member.company_name.presence || grouping_member.siret

    mail(to: mandataire_email, subject: I18n.t('grouping_member_completion_mailer.completed.subject'))
  end
end
