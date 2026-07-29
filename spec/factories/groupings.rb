# frozen_string_literal: true

FactoryBot.define do
  factory :grouping do
    association :public_market, :completed
    legal_type { :conjoint_mandataire_solidaire }

    transient do
      mandataire_market_application { nil }
      skip_mandataire { false }
    end

    after(:create) do |grouping, evaluator|
      next if evaluator.skip_mandataire

      mandataire_application = evaluator.mandataire_market_application ||
                               FactoryBot.create(:market_application, public_market: grouping.public_market, application_mode: :groupement)

      FactoryBot.create(:grouping_member, :mandataire, grouping:, market_application: mandataire_application,
        siret: mandataire_application.siret)
    end
  end
end
