# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::ValidateSiret, type: :interactor do
  describe '.call' do
    context 'when siret is blank' do
      it 'fails with a blank error' do
        result = described_class.call(siret: '')

        expect(result).to be_failure
        expect(result.errors[:siret]).to include(I18n.t('candidate.validations.siret_blank'))
      end

      it 'fails when siret is nil' do
        result = described_class.call(siret: nil)

        expect(result).to be_failure
        expect(result.errors[:siret]).to include(I18n.t('candidate.validations.siret_blank'))
      end
    end

    context 'when siret fails validation' do
      it 'fails with an invalid siret error for a non-numeric value' do
        result = described_class.call(siret: 'NOT-A-SIRET')

        expect(result).to be_failure
        expect(result.errors[:siret]).to include(I18n.t('candidate.validations.siret_invalid'))
      end

      it 'fails with an invalid siret error for wrong length' do
        result = described_class.call(siret: '1234567890')

        expect(result).to be_failure
        expect(result.errors[:siret]).to include(I18n.t('candidate.validations.siret_invalid'))
      end
    end

    context 'when siret is valid' do
      before { allow(SiretValidator).to receive(:valid?).with('73282932000074').and_return(true) }

      it 'succeeds' do
        result = described_class.call(siret: '73282932000074')

        expect(result).to be_success
      end
    end
  end
end
