# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailValidator do
  describe '.valid?' do
    it 'accepts a simple email' do
      expect(described_class.valid?('user@example.com')).to be true
    end

    it 'accepts email with subdomain' do
      expect(described_class.valid?('user@mail.example.com')).to be true
    end

    it 'accepts email with plus sign' do
      expect(described_class.valid?('user+tag@example.com')).to be true
    end

    it 'rejects email without @' do
      expect(described_class.valid?('userexample.com')).to be false
    end

    it 'rejects email without domain' do
      expect(described_class.valid?('user@')).to be false
    end

    it 'rejects email without local part' do
      expect(described_class.valid?('@example.com')).to be false
    end

    it 'rejects email with spaces' do
      expect(described_class.valid?('user @example.com')).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid?(nil)).to be false
    end

    it 'returns false for empty string' do
      expect(described_class.valid?('')).to be false
    end
  end

  describe '#validate_each' do
    subject(:model) { validatable_model.new(email:) }

    let(:validatable_model) do
      stub_const('TestEmailModel', Class.new do
        include ActiveModel::Model
        include ActiveModel::Validations

        attr_accessor :email

        validates :email, email: true
      end)
    end

    context 'with a valid email' do
      let(:email) { 'user@example.com' }

      it { is_expected.to be_valid }
    end

    context 'with an invalid email' do
      let(:email) { 'not-an-email' }

      it { is_expected.not_to be_valid }

      it 'adds an :invalid error on the attribute' do
        model.valid?

        expect(model.errors[:email]).to include(I18n.t('errors.messages.invalid'))
      end
    end
  end
end
