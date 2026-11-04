# frozen_string_literal: true

class GroupingInvitationEmailComponent < ViewComponent::Base
  def initialize(url:, market_name:, mandataire_name:)
    @url = url
    @market_name = market_name
    @mandataire_name = mandataire_name
  end

  def call
    render EmailComponent.new(EmailComponent::Content.new(
      title: t('grouping_invitation_mailer.invitation.subject'),
      intro:,
      cta_label: t('grouping_invitation_mailer.invitation.cta'),
      url: @url
    ))
  end

  private

  def intro
    "#{market_introduction}<br><br>" \
    "#{t('grouping_invitation_mailer.invitation.role_explanation')}<br><br>" \
    "#{t('grouping_invitation_mailer.invitation.edit_notice')}".html_safe
  end

  def market_introduction
    t('grouping_invitation_mailer.invitation.intro',
      mandataire_name: "<strong>#{ERB::Util.html_escape(@mandataire_name)}</strong>",
      market_name: ERB::Util.html_escape(@market_name))
  end
end
