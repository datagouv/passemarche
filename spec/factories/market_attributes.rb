# frozen_string_literal: true

FactoryBot.define do
  factory :market_attribute do
    sequence(:key) { |n| "attribute_#{n}" }
    input_type { :file_upload }
    category_key { 'test_company_identity' }
    subcategory_key { 'test_basic_information' }
    mandatory { false }

    trait :mandatory do
      mandatory { true }
    end

    trait :from_api do
      api_name { 'TestAPI' }
      api_key { 'test_key' }
    end

    trait :inactive do
      deleted_at { Time.current }
    end

    trait :text_input do
      input_type { :text_input }
    end

    trait :checkbox_with_document do
      input_type { :checkbox_with_document }
    end

    trait :file_upload do
      input_type { :file_upload }
    end

    trait :inline_file_upload do
      input_type { :inline_file_upload }
    end

    trait :inline_url_input do
      input_type { :inline_url_input }
    end

    trait :file_or_textarea do
      input_type { :file_or_textarea }
    end

    trait :textarea do
      input_type { :textarea }
    end

    trait :phone do
      input_type { :phone_input }
    end

    trait :email do
      input_type { :email_input }
    end

    trait :radio_with_file_and_text do
      input_type { :radio_with_file_and_text }
    end

    trait :chiffre_affaires do
      input_type { :capacite_economique_financiere_chiffre_affaires_global_annuel }
    end

    trait :effectifs_moyens_annuels do
      input_type { :capacite_economique_financiere_effectifs_moyens_annuels }
    end
  end
end
