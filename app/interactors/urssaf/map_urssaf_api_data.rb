# frozen_string_literal: true

class Urssaf::MapUrssafApiData < MapApiData
  DEFAULT_FILENAME = 'attestation_vigilance.pdf'
  DEFAULT_CONTENT_TYPE = 'application/pdf'

  def extract_value_from_resource(market_attribute)
    return build_document_hash(document_value) if document_related?(market_attribute)

    value = safe_fetch_api_data(market_attribute.api_key)
    begin
      value.dup
    rescue StandardError
      value
    end
  end

  private

  def document_related?(_market_attribute)
    context.bundled_data.data.respond_to?(:document) &&
      context.bundled_data.data.document.present?
  end

  def document_value
    context.bundled_data.data.document
  end

  def safe_fetch_api_data(key)
    context.bundled_data.data.public_send(key.to_s)
  rescue StandardError
    nil
  end

  # Document parsing
  def build_document_hash(value)
    case value
    when Hash
      if value[:pdf_bytes]
        io_obj = StringIO.new(value[:pdf_bytes])
      elsif value[:io]
        io_obj = duplicate_io(value[:io])
      end

      return build_file_hash(io_obj, value) if io_obj
    when IO, StringIO
      return build_file_hash(duplicate_io(value))
    end

    build_file_hash(StringIO.new(value.to_s))
  end

  def build_file_hash(io_obj, metadata = {})
    io_obj.rewind

    {
      io: io_obj,
      filename: metadata[:filename] || DEFAULT_FILENAME,
      content_type: metadata[:content_type] || DEFAULT_CONTENT_TYPE
    }
  end

  # IO duplication
  def duplicate_io(io_obj)
    return StringIO.new(io_obj.string) if io_obj.is_a?(StringIO)

    if io_obj.respond_to?(:read)
      original_pos = safe_pos(io_obj)
      io_obj.rewind
      data = io_obj.read
      restore_pos(io_obj, original_pos)
      return StringIO.new(data)
    end

    raise ArgumentError, "Cannot duplicate IO of type #{io_obj.class}"
  end

  def safe_pos(io_obj)
    io_obj.pos
  rescue StandardError
    nil
  end

  def restore_pos(io_obj, pos_value)
    io_obj.pos = pos_value if pos_value
  rescue StandardError
    nil
  end
end
