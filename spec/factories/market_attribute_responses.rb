# frozen_string_literal: true

FactoryBot.define do
  factory :market_attribute_response do
    association :market_application
    association :market_attribute
    type { 'TextInput' }
    value { nil }

    factory :market_attribute_response_checkbox, class: 'MarketAttributeResponse::Checkbox' do
      type { 'Checkbox' }
      association :market_attribute, :checkbox
    end
    
    factory :market_attribute_response_checkbox_with_document, class: 'MarketAttributeResponse::CheckboxWithDocument' do
      type { 'CheckboxWithDocument' }
      association :market_attribute, :checkbox_with_document
    end

    factory :market_attribute_response_textarea, class: 'MarketAttributeResponse::Textarea' do
      type { 'Textarea' }
      association :market_attribute, :textarea
    end

    factory :market_attribute_response_text_input, class: 'MarketAttributeResponse::TextInput' do
      type { 'TextInput' }
      association :market_attribute, :text_input
    end

    factory :market_attribute_response_file_upload, class: 'MarketAttributeResponse::FileUpload' do
      type { 'FileUpload' }
      association :market_attribute, :file_upload
    end

    factory :market_attribute_response_phone_input, class: 'MarketAttributeResponse::PhoneInput' do
      type { 'PhoneInput' }
      association :market_attribute, :phone_input
    end
  end
end
