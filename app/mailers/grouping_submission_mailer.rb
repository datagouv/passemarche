# frozen_string_literal: true

class GroupingSubmissionMailer < ApplicationMailer
  def submitted(grouping_member)
    @market_name = grouping_member.grouping.public_market.name
    mandataire = grouping_member.grouping.mandataire_grouping_member
    @mandataire_name = mandataire.company_name.presence || mandataire.siret
    attach_inline_image('icon-email-warning.png')

    mail(to: grouping_member.email, subject: I18n.t('grouping_submission_mailer.submitted.subject'))
  end
end
