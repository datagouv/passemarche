# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:key) { |n| "category_#{n}" }
    position { 0 }

    trait :with_labels do
      buyer_label { "Buyer #{key.humanize}" }
      candidate_label { "Candidate #{key.humanize}" }
    end

    trait :inactive do
      deleted_at { Time.current }
    end
  end
end
