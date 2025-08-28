# frozen_string_literal: true

class FieldTranslationImport::CleanCsvFile < ApplicationInteractor
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

  def skip_line?(line, index)
    line.strip.empty? || index < 4
  end

  def handle_line_skip(line, _index, cleaned_lines)
    cleaned_lines << line
  end

  def data_line?(line)
    line.match?(/^[a-z_]+,/) && line.count(',') > 15
  end

  def orphaned_line?(line)
    line.strip == '"' || (line.strip.length < 10 && line.exclude?(','))
  end

  def fix_data_line(lines, start_index)
    line = lines[start_index]

    return [line, 0] unless quote_count_odd?(line)

    consumed_lines = consume_continuation_lines(lines, start_index)
    fixed_line = close_malformed_quotes(line)

    [fixed_line, consumed_lines]
  end

  def quote_count_odd?(line)
    line.count('"').odd?
  end

  def consume_continuation_lines(lines, start_index)
    consumed_lines = 0
    i = start_index + 1

    while i < lines.length && should_consume_line?(lines[i], consumed_lines)
      consumed_lines += 1
      break if lines[i].strip == '"' || lines[i].end_with?('"')

      i += 1
    end

    consumed_lines
  end

  def should_consume_line?(line, consumed_count)
    return false if consumed_count > 10
    return false if data_line?(line)

    true
  end

  def close_malformed_quotes(line)
    return "#{line.rstrip}\"" if line.rstrip.end_with?(',"') || unclosed_quotes?(line)

    line
  end

  def unclosed_quotes?(line)
    line.count('"').positive? && !line.rstrip.end_with?('"')
  end

  def fix_data_line_with_multiline(lines, start_index)
    current_line = lines[start_index]
    quote_count = current_line.count('"')

    return [current_line, 0] if quote_count.even?

    merge_multiline_record(lines, start_index, current_line)
  end

  def merge_multiline_record(lines, start_index, current_line)
    merger = RecordMerger.new(current_line)
    i = start_index + 1

    i = process_merge_line(lines, i, merger) while should_continue_merging?(lines, i, merger)

    [close_malformed_quotes(merger.merged_line), merger.consumed_lines]
  end

  def should_continue_merging?(lines, index, merger)
    index < lines.length && merger.quote_count.odd? && merger.consumed_lines <= 15
  end

  def process_merge_line(lines, index, merger)
    next_line = lines[index]

    if next_line.strip.empty?
      merger.consumed_lines += 1
      return index + 1
    end

    return index if data_line?(next_line)

    merger.merge_line(next_line)
    index + 1
  end

  def append_line_to_record(merged_line, next_line)
    "#{merged_line} #{next_line.strip}"
  end

  # Helper class to manage multiline record merging state
  class RecordMerger
    attr_accessor :merged_line, :consumed_lines

    def initialize(initial_line)
      @merged_line = initial_line
      @consumed_lines = 0
    end

    def quote_count
      @merged_line.count('"')
    end

    def merge_line(next_line)
      @merged_line = "#{@merged_line} #{next_line.strip}"
      @consumed_lines += 1
    end
  end
end
