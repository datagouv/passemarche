# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfGenerationError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts template_name and market_application_id' do
      error = described_class.new(
        'PDF generation failed',
        template_name: 'attestation',
        market_application_id: 123
      )

      expect(error.message).to eq('PDF generation failed')
      expect(error.template_name).to eq('attestation')
      expect(error.market_application_id).to eq(123)
    end

    it 'includes attributes in context' do
      error = described_class.new('Failed', template_name: 'buyer_attestation')

      expect(error.context).to include(template_name: 'buyer_attestation')
    end
  end
end
