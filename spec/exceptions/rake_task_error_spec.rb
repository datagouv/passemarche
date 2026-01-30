# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RakeTaskError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts exit_code' do
      error = described_class.new('Task failed', exit_code: 2)

      expect(error.message).to eq('Task failed')
      expect(error.exit_code).to eq(2)
    end

    it 'defaults exit_code to 1' do
      error = described_class.new('Task failed')

      expect(error.exit_code).to eq(1)
    end

    it 'includes exit_code in context' do
      error = described_class.new('Failed', exit_code: 3)

      expect(error.context).to include(exit_code: 3)
    end
  end
end
