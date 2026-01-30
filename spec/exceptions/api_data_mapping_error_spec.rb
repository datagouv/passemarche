# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiDataMappingError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts api_name, key and original_error' do
      original = TypeError.new('nil is not a hash')
      error = described_class.new(
        'Mapping failed',
        api_name: 'urssaf',
        key: 'effectifs',
        original_error: original
      )

      expect(error.message).to eq('Mapping failed')
      expect(error.api_name).to eq('urssaf')
      expect(error.key).to eq('effectifs')
      expect(error.original_error).to eq(original)
    end

    it 'includes original_error class name in context' do
      original = NoMethodError.new('undefined method')
      error = described_class.new('Failed', original_error: original)

      expect(error.context).to include(original_error_class: 'NoMethodError')
    end
  end
end
