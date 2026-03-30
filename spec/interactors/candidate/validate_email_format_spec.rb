# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::ValidateEmailFormat, type: :interactor do
  describe '.call' do
    context 'when email is blank' do
      it 'fails with a blank error' do
        result = described_class.call(email: '')

        expect(result).to be_failure
        expect(result.errors[:email]).to include(I18n.t('candidate.validations.email_blank'))
      end

      it 'fails when email is nil' do
        result = described_class.call(email: nil)

        expect(result).to be_failure
        expect(result.errors[:email]).to include(I18n.t('candidate.validations.email_blank'))
      end
    end

    context 'when email has an invalid format' do
      it 'fails with an invalid format error' do
        result = described_class.call(email: 'not-an-email')

        expect(result).to be_failure
        expect(result.errors[:email]).to include(I18n.t('candidate.validations.email_invalid'))
      end

      it 'fails for email missing domain' do
        result = described_class.call(email: 'user@')

        expect(result).to be_failure
        expect(result.errors[:email]).to include(I18n.t('candidate.validations.email_invalid'))
      end
    end

    context 'when email is valid' do
      it 'succeeds' do
        result = described_class.call(email: 'user@example.com')

        expect(result).to be_success
      end
    end
  end
end
