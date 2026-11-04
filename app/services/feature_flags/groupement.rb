# frozen_string_literal: true

module FeatureFlags
  class Groupement
    def self.enabled?
      Rails.application.credentials.dig(:groupement, :enabled) == true
    end
  end
end
