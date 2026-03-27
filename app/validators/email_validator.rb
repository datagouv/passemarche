# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  def self.valid?(email)
    email.to_s.match?(URI::MailTo::EMAIL_REGEXP)
  end

  def validate_each(record, attribute, value)
    return if self.class.valid?(value)

    record.errors.add(attribute, :invalid)
  end
end
