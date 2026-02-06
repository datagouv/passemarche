# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotFoundError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts resource_type and identifier' do
      error = described_class.new(
        'Resource not found',
        resource_type: 'Document',
        identifier: 'abc-123'
      )

      expect(error.message).to eq('Resource not found')
      expect(error.resource_type).to eq('Document')
      expect(error.identifier).to eq('abc-123')
    end

    it 'includes attributes in context' do
      error = described_class.new('Not found', resource_type: 'User')

      expect(error.context).to include(resource_type: 'User')
    end
  end
end
