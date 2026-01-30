# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ZipGenerationError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts stage, document_id and filename' do
      error = described_class.new(
        'ZIP generation failed',
        stage: 'attachment',
        document_id: 456,
        filename: 'invoice.pdf'
      )

      expect(error.message).to eq('ZIP generation failed')
      expect(error.stage).to eq('attachment')
      expect(error.document_id).to eq(456)
      expect(error.filename).to eq('invoice.pdf')
    end

    it 'includes attributes in context' do
      error = described_class.new('Failed', stage: 'document_addition')

      expect(error.context).to include(stage: 'document_addition')
    end
  end
end
