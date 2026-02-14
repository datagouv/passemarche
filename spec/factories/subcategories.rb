# frozen_string_literal: true

FactoryBot.define do
  factory :subcategory do
    association :category
    sequence(:key) { |n| "subcategory_#{n}" }
    buyer_label { "Buyer #{key.humanize}" }
    candidate_label { "Candidate #{key.humanize}" }
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
