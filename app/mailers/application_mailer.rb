# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@passemarche.data.gouv.fr'
  layout 'mailer'
end
