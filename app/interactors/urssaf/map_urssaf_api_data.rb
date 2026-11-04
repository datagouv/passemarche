# frozen_string_literal: true

class Urssaf::MapUrssafApiData < MapApiData
  def extract_value_from_resource(market_attribute)
    return duplicated_document_value if document_related?(market_attribute)

    value = safe_fetch_api_data(market_attribute.api_key)
    begin
      value.dup
    rescue TypeError, FrozenError
      value
    end
  end

  private

  def document_related?(_market_attribute)
    context.bundled_data.data.respond_to?(:document) &&
      context.bundled_data.data.document.present?
  end

  def duplicated_document_value
    document_value.merge(io: duplicate_io(document_value[:io]))
  end

  def document_value
    context.bundled_data.data.document
  end

  def duplicate_io(io_obj)
    io_obj.rewind
    StringIO.new(io_obj.read)
  end

  def safe_fetch_api_data(key)
    context.bundled_data.data.public_send(key.to_s)
  rescue NoMethodError => e
    Rails.logger.debug { "[Urssaf::MapUrssafApiData] Key '#{key}' not found in bundled data: #{e.message}" }
    nil
  end
end
