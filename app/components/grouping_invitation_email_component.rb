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
      greeting: t('grouping_invitation_mailer.invitation.greeting'),
      intro:,
      cta_intro: t('grouping_invitation_mailer.invitation.cta_intro'),
      cta_label: t('grouping_invitation_mailer.invitation.cta'),
      url: @url
    ))
  end

  private

  def intro
    "#{t('grouping_invitation_mailer.invitation.intro', mandataire_name: "<strong>#{ERB::Util.html_escape(@mandataire_name)}</strong>".html_safe)} " \
    "&ldquo;<strong>#{ERB::Util.html_escape(@market_name)}</strong>&rdquo;.<br><br>" \
    "#{t('grouping_invitation_mailer.invitation.role_explanation')}".html_safe
  end
end
