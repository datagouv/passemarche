# frozen_string_literal: true

FactoryBot.define do
  factory :market_attribute_response do
    association :market_application
    association :market_attribute, :text_input
    value { nil }

    factory :market_attribute_response_checkbox_with_document, class: 'MarketAttributeResponse::CheckboxWithDocument' do
      association :market_attribute, :checkbox_with_document
    end

    factory :market_attribute_response_textarea, class: 'MarketAttributeResponse::Textarea' do
      association :market_attribute, :textarea
    end

    factory :market_attribute_response_text_input, class: 'MarketAttributeResponse::TextInput' do
      association :market_attribute, :text_input
    end

    factory :market_attribute_response_file_upload, class: 'MarketAttributeResponse::FileUpload' do
      association :market_attribute, :file_upload
    end

    factory :market_attribute_response_file_or_textarea, class: 'MarketAttributeResponse::FileOrTextarea' do
      type { 'FileOrTextarea' }
      association :market_attribute, :file_or_textarea
    end

    factory :market_attribute_response_phone_input, class: 'MarketAttributeResponse::PhoneInput' do
      association :market_attribute, :phone
    end

    factory :market_attribute_response_radio_with_file_and_text, class: 'MarketAttributeResponse::RadioWithFileAndText' do
      association :market_attribute, :radio_with_file_and_text
    end
  end
end
