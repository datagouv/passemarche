# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::GroupingLegalTypePresenter, type: :presenter do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '#grouping' do
    it 'finds the grouping for which the application is mandataire' do
      application = create(:market_application, public_market:, application_mode: :groupement)
      grouping = create(:grouping, public_market:, mandataire_market_application: application)

      expect(described_class.new(application).grouping).to eq(grouping)
    end

    it 'returns nil when the application is not mandataire of any grouping' do
      application = create(:market_application, public_market:, application_mode: :solo)

      expect(described_class.new(application).grouping).to be_nil
    end
  end
end
