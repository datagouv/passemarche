# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_environment_banner', type: :view do
  context 'in non-production environment' do
    it 'renders the environment banner with the current environment name' do
      render partial: 'shared/environment_banner'

      expect(rendered).to have_css('.environment-banner', text: /#{Rails.env}/)
    end
  end

  context 'in production environment' do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production')) }

    it 'does not render the banner' do
      render partial: 'shared/environment_banner'

      expect(rendered.strip).to be_empty
    end
  end
end
