# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'requires an email' do
      user = build(:user, email: nil)

      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it 'requires a valid email format' do
      user = build(:user, email: 'not-an-email')

      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it 'requires a unique email' do
      create(:user, email: 'test@example.com')
      duplicate = build(:user, email: 'test@example.com')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it 'treats emails as case insensitive' do
      create(:user, email: 'test@example.com')
      duplicate = build(:user, email: 'TEST@EXAMPLE.COM')

      expect(duplicate).not_to be_valid
    end
  end

  describe '.find_or_create_by_email' do
    it 'creates a user if none exists' do
      expect { described_class.find_or_create_by_email('new@example.com') }
        .to change(User, :count).by(1)
    end

    it 'returns existing user if email already exists' do
      existing = create(:user, email: 'existing@example.com')

      result = described_class.find_or_create_by_email('existing@example.com')

      expect(result).to eq(existing)
    end

    it 'normalizes email before lookup' do
      existing = create(:user, email: 'existing@example.com')

      result = described_class.find_or_create_by_email('  EXISTING@EXAMPLE.COM  ')

      expect(result).to eq(existing)
    end
  end

  describe 'magic link token' do
    it 'generates a signed token' do
      user = create(:user)

      token = user.generate_token_for(:magic_link)

      expect(token).to be_present
    end

    it 'resolves back to the user' do
      user = create(:user)
      token = user.generate_token_for(:magic_link)

      resolved = User.find_by_token_for(:magic_link, token)

      expect(resolved).to eq(user)
    end

    it 'invalidates previous tokens when authentication_token_sent_at changes' do
      user = create(:user)
      old_token = user.generate_token_for(:magic_link)

      user.update!(authentication_token_sent_at: Time.current)

      expect(User.find_by_token_for(:magic_link, old_token)).to be_nil
    end

    it 'returns nil for an invalid token' do
      expect(User.find_by_token_for(:magic_link, 'invalid-token')).to be_nil
    end
  end
end
