# frozen_string_literal: true

FactoryBot.define do
  factory :market_application do
    association :public_market, :completed
    siret { '73282932000074' }

    sequence(:identifier) { |n| "VR-#{Date.current.year}-TEST#{n.to_s.rjust(8, '0')}" }

    trait :with_provider_user_id do
      provider_user_id { 'editor-user-456' }
    end

    trait :completed do
      completed_at { Time.zone.now }
      sync_status { :sync_completed }
    end

    trait :attests_no_exclusion do
      attests_no_exclusion_motifs { true }
    end

    trait :does_not_attest_no_exclusion do
      attests_no_exclusion_motifs { false }
    end
  end
end
