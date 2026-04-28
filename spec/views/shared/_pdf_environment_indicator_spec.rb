# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_pdf_environment_indicator', type: :view do
  it 'renders only a comment (watermark is applied as PDF overlay)' do
    render partial: 'shared/pdf_environment_indicator'

    expect(rendered.strip).to be_empty
  end
end
