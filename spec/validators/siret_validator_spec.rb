# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SiretValidator, type: :model do
  subject(:model) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :siret

      validates :siret, siret: true

      def self.name
        'TestModel'
      end
    end.new
  end

  describe '.valid?' do
    it 'returns true for a valid SIRET' do
      expect(described_class.valid?('73282932000074')).to be true
    end

    it 'returns true for La Poste SIRET (special case)' do
      expect(described_class.valid?('35600000000048')).to be true
    end

    it 'returns false for invalid Luhn checksum' do
      expect(described_class.valid?('12345678901234')).to be false
    end

    it 'returns false for too short' do
      expect(described_class.valid?('1234567890')).to be false
    end

    it 'returns false for too long' do
      expect(described_class.valid?('123456789012345')).to be false
    end

    it 'returns false for letters' do
      expect(described_class.valid?('1234567890123A')).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid?(nil)).to be false
    end

    it 'returns false for empty string' do
      expect(described_class.valid?('')).to be false
    end
  end

  describe '#validate_each' do
    it 'adds no errors for a valid SIRET' do
      subject.siret = '73282932000074'
      subject.valid?

      expect(subject.errors[:siret]).to be_empty
    end

    it 'adds an error for an invalid SIRET' do
      subject.siret = '12345678901234'
      subject.valid?

      expect(subject.errors[:siret]).to include(I18n.t('errors.messages.invalid'))
    end
  end
end
