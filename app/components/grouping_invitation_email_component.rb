# frozen_string_literal: true

class GroupingInvitationEmailComponent < ViewComponent::Base
  def initialize(url:, market_name:)
    @url = url
    @market_name = market_name
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
    "#{t('grouping_invitation_mailer.invitation.intro')} " \
    "&ldquo;<strong>#{ERB::Util.html_escape(@market_name)}</strong>&rdquo;".html_safe
  end
end
