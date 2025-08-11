# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SiretValidationService, type: :service do
  describe '#call' do
    it 'validates correct SIRET with Luhn checksum' do
      valid_siret = '73282932000074'

      result = described_class.call(valid_siret)

      expect(result).to be true
    end

    it 'accepts La Poste SIRET (special case)' do
      la_poste_siret = '35600000000048'

      result = described_class.call(la_poste_siret)

      expect(result).to be true
    end

    it 'rejects SIRET with invalid Luhn checksum' do
      invalid_siret = '12345678901234'

      result = described_class.call(invalid_siret)

      expect(result).to be false
    end

    it 'rejects invalid format (too short)' do
      result = described_class.call('1234567890')

      expect(result).to be false
    end

    it 'rejects invalid format (too long)' do
      result = described_class.call('123456789012345')

      expect(result).to be false
    end

    it 'rejects invalid format (contains letters)' do
      result = described_class.call('1234567890123A')

      expect(result).to be false
    end

    it 'handles nil input' do
      result = described_class.call(nil)

      expect(result).to be false
    end

    it 'handles empty string' do
      result = described_class.call('')

      expect(result).to be false
    end
  end
end
