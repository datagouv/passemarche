# frozen_string_literal: true

module FeatureFlags
  class LotLimit
    def self.enabled?
      Rails.application.credentials.dig(:lot_limit, :enabled) == true
    end
  end
end
