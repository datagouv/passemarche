# frozen_string_literal: true

class AuthMailer < ApplicationMailer
  def magic_link(user, url, market_name, reconnection: false)
    @user = user
    @url = url
    @market_name = market_name
    @reconnection = reconnection

    subject_key = reconnection ? 'auth_mailer.reconnection_magic_link.subject' : 'auth_mailer.magic_link.subject'
    mail(to: @user.email, subject: I18n.t(subject_key))
  end
end
