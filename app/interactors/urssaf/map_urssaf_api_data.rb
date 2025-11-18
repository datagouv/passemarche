# frozen_string_literal: true

class Urssaf::MapUrssafApiData < MapApiData
  def extract_value_from_resource(market_attribute)
    value = safe_fetch_api_data(market_attribute.api_key)
    value.dup rescue value
  end

  private

  def safe_fetch_api_data(key)
    context.bundled_data.data.public_send(key.to_s)
  rescue StandardError
    nil
  end

  def build_document_hash(value)
    if value.is_a?(Hash) && value[:pdf_bytes]
      io = StringIO.new(value[:pdf_bytes])
      io.rewind
      {
        io: io,
        filename: value[:filename] || 'attestation_vigilance.pdf',
        content_type: value[:content_type] || 'application/pdf'
      }
    elsif value.is_a?(Hash) && value[:io]
      io = duplicate_io(value[:io])
      io.rewind
      {
        io: io,
        filename: value[:filename] || 'attestation_vigilance.pdf',
        content_type: value[:content_type] || 'application/pdf'
      }
    elsif value.is_a?(IO)
      io = duplicate_io(value)
      io.rewind
      {
        io: io,
        filename: 'attestation_vigilance.pdf',
        content_type: 'application/pdf'
      }
    else
      io = StringIO.new(value.to_s)
      io.rewind
      {
        io: io,
        filename: 'attestation_vigilance.pdf',
        content_type: 'application/pdf'
      }
    end
  end

  def duplicate_io(io)
    if io.is_a?(StringIO)
      StringIO.new(io.string).tap(&:rewind)
    elsif io.respond_to?(:read)
      # For File, Tempfile, etc.
      pos = io.pos
      io.rewind
      data = io.read
      io.pos = pos rescue nil
      StringIO.new(data).tap(&:rewind)
    else
      raise ArgumentError, "Cannot duplicate IO of type #{io.class}"
    end
  end
end
