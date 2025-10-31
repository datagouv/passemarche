# frozen_string_literal: true

FactoryBot.define do
  factory :market_application do
    association :public_market, :completed
    siret { nil }

    sequence(:identifier) { |n| "VR-#{Date.current.year}-TEST#{n.to_s.rjust(8, '0')}" }

    trait :completed do
      completed_at { Time.zone.now }
      sync_status { :sync_completed }
    end

    trait :subject_to_prohibition do
      subject_to_prohibition { true }
    end

    trait :not_subject_to_prohibition do
      subject_to_prohibition { false }
    end

    trait :prohibition_not_answered do
      subject_to_prohibition { nil }
    end
  end
end
