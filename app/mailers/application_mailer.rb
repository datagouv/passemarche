# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@passemarche.data.gouv.fr'
  layout 'mailer'

  before_action { attach_inline_image('passe-marche-logo-email.png') }

  private

  def attach_inline_image(filename)
    attachments.inline[filename] = Rails.root.join('app/assets/images', filename).binread
  end
end
