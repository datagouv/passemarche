# frozen_string_literal: true

require 'rails_helper'

# Test implementation
class TestServiceObject < ApplicationServiceObject
  # rubocop:disable Style/OptionalBooleanParameter
  def initialize(should_succeed = true)
    super()
    @should_succeed = should_succeed
  end
  # rubocop:enable Style/OptionalBooleanParameter

  def perform
    if @should_succeed
      @result = 'success result'
    else
      add_error(:base, 'Something went wrong')
      add_error(:name, 'is invalid')
    end
    self
  end
end

RSpec.describe ApplicationServiceObject, type: :service do
  describe 'successful execution' do
    let(:service) { TestServiceObject.new(true).perform }

    it 'reports success' do
      expect(service.success?).to be true
      expect(service.failure?).to be false
    end

    it 'has no errors' do
      expect(service.errors).to be_blank
    end

    it 'returns the result' do
      expect(service.result).to eq('success result')
    end
  end

  describe 'failed execution' do
    let(:service) { TestServiceObject.new(false).perform }

    it 'reports failure' do
      expect(service.success?).to be false
      expect(service.failure?).to be true
    end

    it 'has errors' do
      expect(service.errors).to include(
        base: ['Something went wrong'],
        name: ['is invalid']
      )
    end

    it 'has no result' do
      expect(service.result).to be_nil
    end
  end

  describe 'abstract implementation' do
    it 'raises NotImplementedError if perform is not implemented' do
      service = ApplicationServiceObject.new

      expect { service.perform }.to raise_error(NotImplementedError, 'Subclasses must implement #perform')
    end
  end

  describe 'error handling' do
    let(:service) { TestServiceObject.new }

    it 'allows adding multiple errors to the same key' do
      service.send(:add_error, :name, 'is too short')
      service.send(:add_error, :name, 'is invalid')

      expect(service.errors[:name]).to eq(['is too short', 'is invalid'])
    end

    it 'allows accessing result reader' do
      service.instance_variable_set(:@result, 'test result')

      expect(service.result).to eq('test result')
    end
  end
end
