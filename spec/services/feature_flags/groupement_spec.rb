# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureFlags::Groupement do
  describe '.enabled?' do
    it 'returns true when credentials explicitly enable it' do
      allow(Rails.application.credentials).to receive(:dig).with(:groupement, :enabled).and_return(true)

      expect(described_class.enabled?).to be true
    end

    it 'returns false when credentials explicitly disable it' do
      allow(Rails.application.credentials).to receive(:dig).with(:groupement, :enabled).and_return(false)

      expect(described_class.enabled?).to be false
    end

    it 'returns false when credentials do not define it' do
      allow(Rails.application.credentials).to receive(:dig).with(:groupement, :enabled).and_return(nil)

      expect(described_class.enabled?).to be false
    end
  end
end
