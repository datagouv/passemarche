# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping, type: :model do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

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

  describe '#all_members_completed?' do
    it 'is false when at least one member is not completed' do
      grouping = create(:grouping, public_market:)
      create(:grouping_member, :co_traitant, grouping:, status: :in_progress)

      expect(grouping.all_members_completed?).to be false
    end

    it 'is true when every member, mandataire included, is completed' do
      grouping = create(:grouping, public_market:)
      grouping.mandataire_grouping_member.update!(status: :completed)
      create(:grouping_member, :co_traitant, grouping:, status: :completed)

      expect(grouping.all_members_completed?).to be true
    end
  end

  describe '#any_member_started?' do
    it 'is false when every member is still invited' do
      grouping = create(:grouping, public_market:)
      create(:grouping_member, :co_traitant, grouping:)

      expect(grouping.any_member_started?).to be false
    end

    it 'is true when at least one member is in_progress or completed' do
      grouping = create(:grouping, public_market:)
      create(:grouping_member, :co_traitant, grouping:, status: :in_progress)

      expect(grouping.any_member_started?).to be true
    end
  end
end
