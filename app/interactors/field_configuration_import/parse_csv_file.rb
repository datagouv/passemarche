# frozen_string_literal: true

require 'csv'

class FieldConfigurationImport::ParseCsvFile < ApplicationInteractor
  HEADER_ROW_INDEX = 3
  DATA_START_INDEX = 4
  MINIMUM_LINES = 5

  def call
    context.csv_lines = File.readlines(context.csv_file_path)

    validate_csv_structure
    return if context.failure?

    parse_headers_and_rows
  end

  private

  def validate_csv_structure
    return if context.csv_lines.length >= MINIMUM_LINES

    context.fail!(message: "Invalid CSV: expected at least #{MINIMUM_LINES} lines")
  end

  def parse_headers_and_rows
    context.headers = CSV.parse_line(
      context.csv_lines[HEADER_ROW_INDEX].chomp,
      liberal_parsing: true
    )

    context.parsed_rows = parse_data_rows
  end

  def parse_data_rows
    context.csv_lines[DATA_START_INDEX..].each_with_index.filter_map { |line, index|
      next if line.strip.blank?

      parse_single_row(line, index)
    }.compact
  end

  def parse_single_row(line, index)
    row_data = CSV.parse_line(line.chomp, liberal_parsing: true)
    return nil if row_data.blank?

    build_csv_row(row_data, index)
  rescue CSV::MalformedCSVError => e
    handle_malformed_row(index, e.message)
    nil
  end

  def build_csv_row(row_data, index)
    raw_data = context.headers.zip(row_data).to_h
    row = CsvRowData.new(raw_data, index + DATA_START_INDEX + 1)

    collect_validation_errors(row) unless row.valid?

    row
  end

  def handle_malformed_row(index, error_message)
    record_malformed_row(index + DATA_START_INDEX + 1, error_message)
    increment_stat(:skipped)
  end

  def collect_validation_errors(row)
    return unless row.should_import?

    context.statistics[:validation_errors] ||= []
    context.statistics[:validation_errors] << {
      line: row.line_number,
      key: row.key,
      errors: row.errors.full_messages
    }
  end

  def record_malformed_row(line_number, error)
    context.statistics[:malformed_rows] ||= []
    context.statistics[:malformed_rows] << { line: line_number, error: error }
  end

  def increment_stat(key)
    context.statistics[key] += 1
  end
end
