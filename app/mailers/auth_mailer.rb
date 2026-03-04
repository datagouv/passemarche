# frozen_string_literal: true

class AuthMailer < ApplicationMailer
  def magic_link(user, url, market_name)
    @user = user
    @url = url
    @market_name = market_name

    mail(to: @user.email, subject: I18n.t('auth_mailer.magic_link.subject'))
  end
end
