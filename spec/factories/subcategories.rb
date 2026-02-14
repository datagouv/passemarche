# frozen_string_literal: true

FactoryBot.define do
  factory :subcategory do
    association :category
    sequence(:key) { |n| "subcategory_#{n}" }
    buyer_label { "Buyer #{key.humanize}" }
    candidate_label { "Candidate #{key.humanize}" }
    position { 0 }

    after(:build) do |subcategory|
      subcategory.buyer_category ||= subcategory.category
      subcategory.candidate_category ||= subcategory.category
    end

    trait :with_labels do
      buyer_label { "Buyer #{key.humanize}" }
      candidate_label { "Candidate #{key.humanize}" }
    end

    trait :inactive do
      deleted_at { Time.current }
    end
  end
end
