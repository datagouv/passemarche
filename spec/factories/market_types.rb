# frozen_string_literal: true

FactoryBot.define do
  factory :market_type do
    initialize_with { MarketType.find_or_create_by(code: code) }

    code { 'supplies' }

    trait :services do
      code { 'services' }
    end

    trait :works do
      code { 'works' }
    end

    trait :defense do
      code { 'defense' }
    end

    trait :inactive do
      deleted_at { Time.current }
    end
  end
end
