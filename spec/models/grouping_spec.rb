# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping, type: :model do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  describe '#legal_type' do
    it 'accepts conjoint, solidaire and conjoint_mandataire_solidaire' do
      grouping = build(:grouping, public_market:, legal_type: :conjoint)
      expect(grouping).to be_legal_type_conjoint

      grouping.legal_type = :solidaire
      expect(grouping).to be_legal_type_solidaire

      grouping.legal_type = :conjoint_mandataire_solidaire
      expect(grouping).to be_legal_type_conjoint_mandataire_solidaire
    end
  end
end
