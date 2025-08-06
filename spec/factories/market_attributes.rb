# frozen_string_literal: true

FactoryBot.define do
  factory :market_attribute do
    sequence(:key) { |n| "attribute_#{n}" }
    input_type { :file_upload }
    category_key { 'company_identity' }
    subcategory_key { 'basic_information' }
    from_api { false }
    required { false }

    trait :required do
      required { true }
    end

    trait :from_api do
      from_api { true }
    end

    trait :inactive do
      deleted_at { Time.current }
    end

    trait :text_input do
      input_type { :text_input }
    end

    trait :checkbox do
      input_type { :checkbox }
    end
  end
end
