# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  describe '#can_modify?' do
    it 'returns true for admin role' do
      admin = build(:admin_user, role: :admin)

      expect(admin.can_modify?).to be(true)
    end

    it 'returns false for lecteur role' do
      lecteur = build(:admin_user, role: :lecteur)

      expect(lecteur.can_modify?).to be(false)
    end
  end
end
