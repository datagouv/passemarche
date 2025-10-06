# frozen_string_literal: true

# Generic concern for MarketAttributeResponse types that need to store
# repeating items (e.g., list of persons, list of projects, list of references).
#
# Storage Structure:
#   {
#     "items" => {
#       "1738234567890" => { "field_name" => "value" },
#       "1738234567891" => { "field_name" => "value" }
#     }
#   }
#
# Usage:
#   class MarketAttributeResponse::MyRepeatableField < MarketAttributeResponse
#     include RepeatableField
#
#     def self.item_schema
#       {
#         'field_name' => { type: 'string', required: true },
#         'another_field' => { type: 'text', required: false }
#       }
#     end
#   end
#
module MarketAttributeResponse::RepeatableField
  extend ActiveSupport::Concern

  included do
    include MarketAttributeResponse::FileAttachable
    include MarketAttributeResponse::JsonValidatable
  end

  def items
    value&.dig('items') || {}
  end

  def items=(items_hash)
    self.value = { 'items' => items_hash.is_a?(Hash) ? items_hash : {} }
    value_will_change!
  end

  def items_ordered
    items.sort_by { |timestamp, _| timestamp.to_i }.to_h
  end

  def get_item_field(item_timestamp, field_name)
    items[item_timestamp.to_s]&.dig(field_name.to_s)
  end

  def set_item_field(item_timestamp, field_name, field_value)
    ensure_item_exists(item_timestamp)
    items[item_timestamp.to_s][field_name.to_s] = field_value.presence
    value_will_change!
    self.value = value.dup
  end

  def assign_attributes(attributes)
    process_repeatable_attributes(attributes)
    super(attributes.except(*repeatable_param_keys))
  end

  def process_repeatable_attributes(attributes)
    @processed_repeatable_keys = []
    repeatable_params = extract_repeatable_params(attributes)
    @processed_repeatable_keys = repeatable_params.keys

    process_repeatable_params(repeatable_params)
  end

  def repeatable_param_keys
    @processed_repeatable_keys || []
  end

  def item_prefix
    'item'
  end

  def specialized_document_fields
    []
  end

  def cleanup_old_specialized_documents?
    false
  end

  def attach_specialized_document(timestamp, field_name, file)
    purge_old_specialized_documents(timestamp, field_name) if cleanup_old_specialized_documents?

    documents.attach(
      io: file.respond_to?(:tempfile) ? file.tempfile : file,
      filename: file.original_filename,
      content_type: file.content_type,
      metadata: {
        field_type: 'specialized',
        item_timestamp: timestamp.to_s,
        field_name: field_name.to_s
      }
    )
  end

  def purge_old_specialized_documents(timestamp, field_name)
    return unless documents.attached?

    documents.select do |doc|
      doc.metadata['field_type'] == 'specialized' &&
        doc.metadata['item_timestamp'] == timestamp.to_s &&
        doc.metadata['field_name'] == field_name.to_s
    end.each(&:purge)
  end

  def get_specialized_document(timestamp, field_name)
    return nil unless documents.attached?

    matching_docs = documents.select do |doc|
      doc.metadata['field_type'] == 'specialized' &&
        doc.metadata['item_timestamp'] == timestamp.to_s &&
        doc.metadata['field_name'] == field_name.to_s
    end

    matching_docs.max_by(&:created_at)
  end

  def generic_documents
    return [] unless documents.attached?

    documents.reject do |doc|
      doc.metadata['field_type'] == 'specialized'
    end
  end

  private

  def ensure_item_exists(timestamp)
    self.value = {} if value.blank?
    value['items'] = {} if value['items'].blank?
    value['items'][timestamp.to_s] = {} unless value['items'].key?(timestamp.to_s)
  end

  def extract_repeatable_params(attributes)
    prefix = Regexp.escape(item_prefix)
    attributes.select { |key, _| key.to_s.match?(/\A#{prefix}_\d+_/) }
  end

  def process_repeatable_params(params)
    grouped = params.group_by do |key, _|
      match = key.to_s.match(/\A#{Regexp.escape(item_prefix)}_(\d+)_/)
      match ? match[1] : nil
    end

    grouped.each do |timestamp, fields|
      next if timestamp.nil?

      process_item_fields(timestamp, fields)
    end
  end

  def process_item_fields(timestamp, fields)
    fields.each do |key, value|
      field_name = extract_field_name(key)
      next if field_name.nil?

      if field_name == '_destroy'
        handle_destroy_flag(timestamp, value) if value.to_s == '1'
      elsif specialized_document_fields.include?(field_name)
        handle_specialized_document(timestamp, field_name, value)
      else
        set_item_field(timestamp, field_name, value)
      end
    end
  end

  def extract_field_name(key)
    match = key.to_s.match(/\A#{Regexp.escape(item_prefix)}_(\d+)_(.+)\z/)
    match ? match[2] : nil
  end

  def handle_destroy_flag(timestamp, _value)
    self.value ||= {}
    self.value['items'] ||= {}
    self.value['items'].delete(timestamp.to_s)
    value_will_change!
  end

  def handle_specialized_document(timestamp, field_name, file_or_files)
    if file_or_files.is_a?(Array)
      handle_multiple_document(timestamp, field_name, file_or_files)
    elsif file_or_files.respond_to?(:tempfile)
      attach_specialized_document(timestamp, field_name, file_or_files)
      set_item_field(timestamp, field_name, 'attached')
    else
      set_item_field(timestamp, field_name, file_or_files)
    end
  end

  class_methods do
    def item_schema
      raise NotImplementedError, "#{name} must implement item_schema class method"
    end
  end

  def handle_multiple_document(timestamp, field_name, files)
    files.each do |file|
      next if file.blank?

      attach_specialized_document(timestamp, field_name, file) if file.respond_to?(:tempfile)
    end
    set_item_field(timestamp, field_name, 'attached') if files.any?
  end
end
