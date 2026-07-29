# frozen_string_literal: true

module Candidate
  module GroupementFeatureGuard
    extend ActiveSupport::Concern

    included do
      before_action :ensure_groupement_feature_enabled
    end

    private

    def ensure_groupement_feature_enabled
      head :not_found unless FeatureFlags::Groupement.enabled?
    end
  end
end
