# frozen_string_literal: true

# Feature flags are toggled via singleton method overrides (RSpec mocks
# are not available in Cucumber step definitions). Disabled by default
# so existing scenarios stay independent from the real credentials value;
# scenarios that test the groupement flow enable it explicitly.
Before do
  FeatureFlags::Groupement.define_singleton_method(:enabled?) { false }
end

After do
  FeatureFlags::Groupement.define_singleton_method(:enabled?) do
    Rails.application.credentials.dig(:groupement, :enabled) == true
  end
end
