# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationService do
  let(:test_service_class) do
    Class.new(ApplicationService) do
      def initialize(value)
        @value = value
      end

      def call
        @value
      end
    end
  end

  describe '.call' do
    it 'creates an instance and calls the call method' do
      result = test_service_class.call('test_value')
      
      expect(result).to eq('test_value')
    end
  end

  describe '#call' do
    it 'raises NotImplementedError when not overridden' do
      expect { ApplicationService.new.call }.to raise_error(NotImplementedError)
    end
  end
end