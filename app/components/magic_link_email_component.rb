# frozen_string_literal: true

class MagicLinkEmailComponent < ViewComponent::Base
  def initialize(url:, market_name:, reconnection: false)
    @url = url
    @market_name = market_name
    @reconnection = reconnection
  end

  def call
    render EmailComponent.new(EmailComponent::Content.new(
      title: t(reconnection? ? 'auth_mailer.reconnection_magic_link.subject' : 'auth_mailer.magic_link.subject'),
      greeting: t(reconnection? ? 'auth_mailer.reconnection_magic_link.greeting' : 'auth_mailer.magic_link.greeting'),
      intro:,
      cta_intro: t(reconnection? ? 'auth_mailer.reconnection_magic_link.cta_intro' : 'auth_mailer.magic_link.cta_intro'),
      cta_label: t(reconnection? ? 'auth_mailer.reconnection_magic_link.cta' : 'auth_mailer.magic_link.cta'),
      url: @url,
      warning: reconnection? ? nil : t('auth_mailer.magic_link.warning')
    ))
  end

  private

  def reconnection?
    @reconnection
  end

  def intro
    if reconnection?
      "#{t('auth_mailer.reconnection_magic_link.intro')}<br>" \
      "#{t('auth_mailer.reconnection_magic_link.market_intro')} " \
      "&ldquo;<strong>#{ERB::Util.html_escape(@market_name)}</strong>&rdquo;".html_safe
    else
      "#{t('auth_mailer.magic_link.intro')} " \
      "&ldquo;<strong>#{ERB::Util.html_escape(@market_name)}</strong>&rdquo;".html_safe
    end
  end
end
