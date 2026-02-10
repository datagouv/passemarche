# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminUser do
  describe 'role enum' do
    it 'defines lecteur and admin roles' do
      expect(described_class.roles).to eq('lecteur' => 0, 'admin' => 1)
    end

    it 'defaults to lecteur for new records' do
      user = described_class.new(email: 'test@example.com', password: 'password123')
      expect(user).to be_lecteur
    end
  end

  describe '#can_modify?' do
    it 'returns true for admin role' do
      user = build(:admin_user, role: :admin)
      expect(user.can_modify?).to be true
    end

    it 'returns false for lecteur role' do
      user = build(:admin_user, role: :lecteur)
      expect(user.can_modify?).to be false
    end
  end
end
