# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IdentifierGenerationService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  describe '.call' do
    it 'generates an identifier with VR-YYYY-XXXXXXXXXXXX format' do
      identifier = described_class.call

      expect(identifier).to match(/\AVR-\d{4}-[A-Z0-9]{#{described_class::SUFFIX_LENGTH}}\z/o)
    end

    it 'includes the current year' do
      identifier = described_class.call
      current_year = Time.zone.now.year

      expect(identifier).to start_with("VR-#{current_year}-")
    end

    it 'generates unique identifiers' do
      base_time = Time.zone.parse('2024-01-01 12:00:00')
      identifiers = []

      100.times do |i|
        travel_to(base_time + i.seconds) do
          identifiers << described_class.call
        end
      end

      expect(identifiers.uniq.length).to eq(100)
    end

    it 'generates 12-character alphanumeric suffix' do
      identifier = described_class.call
      suffix = identifier.split('-').last

      expect(suffix).to match(/\A[A-Z0-9]{#{described_class::SUFFIX_LENGTH}}\z/o)
      expect(suffix.length).to eq(described_class::SUFFIX_LENGTH)
    end
  end

  describe '#call' do
    it 'generates the same identifier format as class method' do
      service = described_class.new
      identifier = service.call

      expect(identifier).to match(/\AVR-\d{4}-[A-Z0-9]{#{described_class::SUFFIX_LENGTH}}\z/o)
    end
  end
end
