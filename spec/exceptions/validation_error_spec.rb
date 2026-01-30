# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValidationError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts errors array' do
      error = described_class.new(
        'Validation failed',
        errors: ['email is invalid', 'name is required']
      )

      expect(error.message).to eq('Validation failed')
      expect(error.errors).to eq(['email is invalid', 'name is required'])
    end

    it 'defaults errors to empty array' do
      error = described_class.new('Failed')

      expect(error.errors).to eq([])
    end

    it 'includes errors in context' do
      error = described_class.new('Failed', errors: ['field required'])

      expect(error.context).to include(errors: ['field required'])
    end
  end
end
