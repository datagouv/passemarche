# frozen_string_literal: true

namespace :field_configuration do
  desc 'Import field configuration from CSV file into database'
  task import: :environment do
    execute_field_configuration_import
  rescue RakeTaskError => e
    puts e.message
    exit e.exit_code
  end

  desc 'Import field configuration from custom CSV file path'
  task :import_from_file, [:file_path] => :environment do |_task, args|
    execute_field_configuration_import_from_file(args[:file_path])
  rescue RakeTaskError => e
    puts e.message
    exit e.exit_code
  end

  desc 'Validate CSV file structure without importing'
  task :validate, [:file_path] => :environment do |_task, args|
    file_path = args[:file_path] || Rails.root.join('config/form_fields/fields.csv')
    validate_csv_file(file_path)
  rescue RakeTaskError => e
    puts e.message
    exit e.exit_code
  end

  private

  def execute_field_configuration_import
    puts '🚀 Starting field configuration import...'

    begin
      service = FieldConfigurationImportService.new
      stats = service.perform

      raise_import_errors(service) if service.failure?
      display_import_success(stats)
    rescue StandardError => e
      raise_import_failure(e)
    end
  end

  def execute_field_configuration_import_from_file(file_path)
    raise_missing_file_path_error if file_path.blank?

    puts "🚀 Starting field configuration import from #{file_path}..."

    begin
      service = FieldConfigurationImportService.new(csv_file_path: file_path)
      stats = service.perform

      raise_import_errors(service) if service.failure?
      display_import_success(stats)
    rescue StandardError => e
      raise_import_failure(e)
    end
  end

  def validate_csv_file(file_path)
    puts "🔍 Validating CSV file: #{file_path}"

    result = FieldConfigurationImport.call(csv_file_path: file_path)

    if result.success?
      display_validation_success(result.statistics)
    else
      raise_validation_failure(result.message)
    end
  rescue StandardError => e
    raise_validation_failure(e.message)
  end

  def display_validation_success(stats)
    puts "\n✅ CSV file is valid!"
    puts "   • #{stats[:processed]} rows would be processed"
    puts "   • #{stats[:created]} fields would be created"
    puts "   • #{stats[:updated]} fields would be updated"
  end

  def raise_validation_failure(message)
    error_message = "\n❌ Validation failed:\n   #{message}"
    raise RakeTaskError, error_message
  end

  def raise_missing_file_path_error
    error_message = "❌ Error: Please provide a file path\nUsage: bin/rails field_configuration:import_from_file[/path/to/fields.csv]"
    raise RakeTaskError, error_message
  end

  def raise_import_errors(service)
    error_message = "\n❌ Import failed with errors:\n"
    service.errors.each do |key, messages|
      messages.each { |msg| error_message += "   #{key}: #{msg}\n" }
    end
    raise RakeTaskError, error_message.chomp
  end

  def display_import_success(stats)
    puts "\n✅ Import completed successfully!"
    display_import_results(stats)
    display_import_warnings(stats)
    display_current_status(stats)
  end

  def display_import_results(stats)
    puts '📊 Results:'
    puts "   • #{stats[:processed]} rows processed"
    puts "   • #{stats[:created]} new fields created"
    puts "   • #{stats[:updated]} fields updated"
    puts "   • #{stats[:skipped]} rows skipped"
    puts "   • #{stats[:soft_deleted]} fields soft deleted"
  end

  def display_current_status(stats)
    puts "\n🎯 Current status:"
    puts "   • #{stats[:total_active_attributes]} active field(s)"
    puts "   • #{stats[:total_market_types]} active market type(s)"
    puts "   • #{stats[:total_associations]} market type associations"
  end

  def display_import_warnings(stats)
    display_missing_market_types_warning(stats) if stats[:missing_market_types]&.any?
    display_validation_errors_warning(stats) if stats[:validation_errors]&.any?
    display_malformed_rows_warning(stats) if stats[:malformed_rows]&.any?
  end

  def display_missing_market_types_warning(stats)
    puts "\n⚠️  Missing MarketTypes:"
    stats[:missing_market_types].each do |code|
      puts "   • #{code} not found in database"
    end
  end

  def display_validation_errors_warning(stats)
    validation_errors = stats[:validation_errors]
    puts "\n❌ Validation Errors:"
    puts "   • #{validation_errors.count} rows failed validation"

    display_error_samples(validation_errors)
    display_remaining_error_count(validation_errors)
  end

  def display_error_samples(validation_errors)
    validation_errors.first(5).each do |error|
      key_info = error[:key].present? ? " (#{error[:key]})" : ''
      puts "     - Line #{error[:line]}#{key_info}: #{error[:errors].join(', ')}"
    end
  end

  def display_remaining_error_count(validation_errors)
    return unless validation_errors.count > 5

    puts "     - ... and #{validation_errors.count - 5} more validation errors"
  end

  def display_malformed_rows_warning(stats)
    malformed_rows = stats[:malformed_rows]
    puts "\n⚠️  CSV Parsing Warnings:"
    puts "   • #{malformed_rows.count} malformed CSV rows skipped"

    malformed_rows.first(3).each do |error|
      puts "     - Line #{error[:line]}: #{error[:error]}"
    end

    return unless malformed_rows.count > 3

    puts "     - ... and #{malformed_rows.count - 3} more"
  end

  def raise_import_failure(error)
    error_message = "\n❌ Import failed with error:\n   #{error.class}: #{error.message}"

    if Rails.env.development?
      error_message += "\n\n🔍 Backtrace:\n"
      error.backtrace.first(10).each { |line| error_message += "   #{line}\n" }
    end

    raise RakeTaskError, error_message.chomp
  end
end
