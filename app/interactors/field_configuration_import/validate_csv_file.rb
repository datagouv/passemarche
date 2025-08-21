# frozen_string_literal: true

class FieldConfigurationImport::ValidateCsvFile < ApplicationInteractor
  def call
    validate_file_path
    validate_file_existence
    validate_file_type
    validate_file_readability
  end

  private

  def validate_file_path
    return unless context.csv_file_path.nil?

    fail_with_message('CSV file not found: ')
  end

  def validate_file_existence
    return if File.exist?(context.csv_file_path)

    fail_with_message("CSV file not found: #{context.csv_file_path}")
  end

  def validate_file_type
    return if File.file?(context.csv_file_path)

    fail_with_message("CSV file not found: #{context.csv_file_path}")
  end

  def validate_file_readability
    return if File.readable?(context.csv_file_path)

    fail_with_message("CSV file not readable: #{context.csv_file_path}")
  end

  def fail_with_message(message)
    context.message = message
    context.fail!(message: message)
  end
end
