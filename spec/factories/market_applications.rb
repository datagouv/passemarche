# frozen_string_literal: true

FactoryBot.define do
  factory :market_application do
    association :public_market, :completed
    siret { '12345678901234' }

    sequence(:identifier) { |n| "VR-#{Date.current.year}-TEST#{n.to_s.rjust(8, '0')}" }

    trait :completed do
      completed_at { Time.zone.now }
      sync_status { :sync_completed }
    end
  end
end
