# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_pdf_environment_indicator', type: :view do
  context 'in non-production environment' do
    it 'renders the watermark as a tiled SVG background' do
      render partial: 'shared/pdf_environment_indicator'

      expect(rendered).to include('background-image')
      expect(rendered).to include('Attestation%20de%20test')
    end
  end

  context 'in production environment' do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production')) }

    it 'does not render anything' do
      render partial: 'shared/pdf_environment_indicator'

      expect(rendered.strip).to be_empty
    end
  end
end
