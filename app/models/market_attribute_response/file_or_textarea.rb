class MarketAttributeResponse::FileOrTextarea < MarketAttributeResponse
  include MarketAttributeResponse::FileAttachable
  include MarketAttributeResponse::JsonValidatable
  include MarketAttributeResponse::TextValidatable

  # Behavior: at least one of the two fields (text or file) must be provided
  validate :text_or_file_presence

  def self.json_schema_properties
    %i[text]
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end

  private

  def text_or_file_presence
    return unless text.blank? && !documents.attached?

    errors.add(
      :base,
      I18n.t('activerecord.errors.models.market_attribute_response/file_or_textarea.attributes.file_or_textarea_blank')
    )
  end
end
