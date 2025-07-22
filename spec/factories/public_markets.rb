# frozen_string_literal: true

FactoryBot.define do
  factory :public_market do
    editor
    identifier { nil }
    completed_at { nil }

    trait :completed do
      completed_at { Time.current }
    end
  end
end
