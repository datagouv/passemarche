# frozen_string_literal: true

namespace :field_translations do
  desc 'Import translations from CSV file into form_fields.fr.yml'
  task import: :environment do
    execute_field_translation_import
  end

  desc 'Import translations from custom CSV file path'
  task :import_from_file, [:file_path] => :environment do |_task, args|
    execute_field_translation_import_from_file(args[:file_path])
  end

  private

  def execute_field_translation_import
    puts '🌐 Starting field translation import...'

    begin
      run_translation_import_process
    rescue StandardError => e
      handle_import_failure(e)
    end
  end

  def run_translation_import_process
    result = FieldTranslationImport.call(csv_file_path: Rails.root.join('config/form_fields/fields.csv'))

    handle_translation_import_errors(result) if result.failure?
    display_translation_import_success(result.statistics)
  end

  def handle_translation_import_errors(result)
    puts "\n❌ Translation import failed with errors:"
    puts "   #{result.message}"
    exit 1
  end

  def display_translation_import_success(stats)
    puts "\n✅ Translation import completed successfully!"
    display_translation_import_results(stats)
    display_translation_warnings(stats)
  end

  def display_translation_import_results(stats)
    puts '📊 Translation Results:'
    puts "   • #{stats[:fields_processed]} fields processed"
    puts "   • #{stats[:total_categories]} categories translated"
    puts "   • #{stats[:total_subcategories]} subcategories translated"
    puts "   • #{stats[:total_fields]} field translations extracted"
    puts "   • #{stats[:fields_with_names]} fields with names"
    puts "   • #{stats[:fields_with_descriptions]} fields with descriptions"

    return unless stats[:translation_file_updated]

    puts '   • Translation file updated: config/locales/form_fields.fr.yml'
  end

  def display_translation_warnings(stats)
    return unless stats[:warnings]&.any?

    puts "\n⚠️  Translation Warnings:"
    stats[:warnings].each do |warning|
      puts "   • #{warning}"
    end
  end

  def execute_field_translation_import_from_file(file_path)
    validate_file_path(file_path)
    puts "🌐 Starting field translation import from #{file_path}..."

    begin
      run_custom_file_translation_import(file_path)
    rescue StandardError => e
      puts "\n❌ Translation import failed: #{e.message}"
      exit 1
    end
  end

  def validate_file_path(file_path)
    if file_path.blank?
      puts '❌ Error: Please provide a file path'
      puts 'Usage: bin/rails field_translations:import_from_file[/path/to/fields.csv]'
      exit 1
    end

    return if File.exist?(file_path)

    puts "❌ Error: File not found: #{file_path}"
    exit 1
  end

  def run_custom_file_translation_import(file_path)
    result = FieldTranslationImport.call(csv_file_path: file_path)

    handle_translation_import_errors(result) if result.failure?
    display_custom_translation_import_success(result.statistics)
  end

  def display_custom_translation_import_success(stats)
    puts "\n✅ Translation import completed successfully!"
    display_translation_import_results(stats)
    display_translation_warnings(stats)
  end

  def handle_import_failure(error)
    puts "\n❌ Translation import failed with error:"
    puts "   #{error.class}: #{error.message}"

    if Rails.env.development?
      puts "\n🔍 Backtrace:"
      error.backtrace.first(10).each { |line| puts "   #{line}" }
    end

    exit 1
  end
end
