# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts action and resource' do
      error = described_class.new(
        'Permission denied',
        action: 'delete',
        resource: 'MarketApplication#123'
      )

      expect(error.message).to eq('Permission denied')
      expect(error.action).to eq('delete')
      expect(error.resource).to eq('MarketApplication#123')
    end

    it 'includes attributes in context' do
      error = described_class.new('Denied', action: 'update')

      expect(error.context).to include(action: 'update')
    end
  end
end
