# frozen_string_literal: true

module WizardInvalidStepNotFound
  extend ActiveSupport::Concern

  included do
    rescue_from Wicked::Wizard::InvalidStepError, with: :render_wizard_step_not_found
  end

  private

  def render_wizard_step_not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end
end
