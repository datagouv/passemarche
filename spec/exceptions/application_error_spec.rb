# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationError do
  describe '#initialize' do
    it 'can be raised with just a message' do
      error = described_class.new('Something went wrong')

      expect(error.message).to eq('Something went wrong')
      expect(error.context).to eq({})
    end

    it 'can be raised with a message and context' do
      error = described_class.new('Failed to process', context: { user_id: 123, action: 'update' })

      expect(error.message).to eq('Failed to process')
      expect(error.context).to eq({ user_id: 123, action: 'update' })
    end

    it 'can be raised without any arguments' do
      error = described_class.new

      expect(error.message).to eq('ApplicationError')
      expect(error.context).to eq({})
    end
  end

  describe '#to_h' do
    it 'returns a hash representation of the error' do
      error = described_class.new('Test error', context: { key: 'value' })

      expect(error.to_h).to eq({
        error_class: 'ApplicationError',
        message: 'Test error',
        context: { key: 'value' }
      })
    end

    it 'includes the correct class name for subclasses' do
      subclass = Class.new(described_class)
      stub_const('CustomError', subclass)
      error = CustomError.new('Custom error')

      expect(error.to_h[:error_class]).to eq('CustomError')
    end
  end

  it 'is a subclass of StandardError' do
    expect(described_class).to be < StandardError
  end

  it 'can be rescued as StandardError' do
    expect do
      raise described_class, 'test'
    rescue StandardError => e
      expect(e).to be_a(described_class)
    end.not_to raise_error
  end
end
