# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Buyer::RecentOptionalCategoryVisit do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, editor:) }

  describe '.visited?' do
    it 'returns false when the category was never marked visited' do
      expect(described_class.visited?(public_market, :motifs_exclusion)).to be false
    end

    it 'returns true after the category was marked visited' do
      described_class.mark_visited(public_market, :motifs_exclusion)

      expect(described_class.visited?(public_market, :motifs_exclusion)).to be true
    end

    it 'does not leak between different public markets' do
      other_market = create(:public_market, editor:)
      described_class.mark_visited(public_market, :motifs_exclusion)

      expect(described_class.visited?(other_market, :motifs_exclusion)).to be false
    end

    it 'does not leak between different categories' do
      described_class.mark_visited(public_market, :motifs_exclusion)

      expect(described_class.visited?(public_market, :identite_entreprise)).to be false
    end

    it 'expires after the configured duration' do
      described_class.mark_visited(public_market, :motifs_exclusion)

      travel_to(described_class::EXPIRY.from_now + 1.minute) do
        expect(described_class.visited?(public_market, :motifs_exclusion)).to be false
      end
    end
  end
end
