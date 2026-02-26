# frozen_string_literal: true

class FieldConfigurationImport::CleanCsvFile < ApplicationInteractor
  def call
    return unless needs_cleaning?

    clean_malformed_csv_file
    update_context_with_cleaned_path
  end

  private

  def needs_cleaning?
    File.exist?(context.csv_file_path)
  end

  def clean_malformed_csv_file
    content = File.read(context.csv_file_path)
    cleaned_content = fix_malformed_quotes(content)

    context.cleaned_csv_path = generate_cleaned_path
    File.write(context.cleaned_csv_path, cleaned_content)
  end

  def update_context_with_cleaned_path
    context.original_csv_path = context.csv_file_path
    context.csv_file_path = context.cleaned_csv_path
  end

  def generate_cleaned_path
    context.csv_file_path.sub('.csv', '_cleaned.csv')
  end

  def fix_malformed_quotes(content)
    lines = content.split("\n")
    fixed_lines = []
    current_record = ''

    lines.each_with_index do |line, index|
      if should_skip_line?(index, line)
        fixed_lines << line
        next
      end

      current_record = build_current_record(current_record, line)
      current_record = finalize_if_balanced(fixed_lines, current_record)
    end

    finalize_record(fixed_lines, current_record)
    fixed_lines.join("\n")
  end

  def should_skip_line?(index, line)
    index < 4 || (index < 10 && line.strip.empty?)
  end

  def build_current_record(current_record, line)
    return line if current_record.empty?

    "#{current_record} #{line.strip}"
  end

  def quotes_balanced?(record)
    record.count('"').even?
  end

  def finalize_if_balanced(fixed_lines, current_record)
    return '' if add_balanced_record(fixed_lines, current_record)

    current_record
  end

  def add_balanced_record(fixed_lines, current_record)
    return false unless quotes_balanced?(current_record)

    fixed_lines << current_record
    true
  end

  def finalize_record(fixed_lines, current_record)
    return if current_record.empty?

    current_record += '"' if current_record.count('"').odd?
    fixed_lines << current_record
  end
end
