class MarketAttributeResponse::FileUpload < MarketAttributeResponse
  include MarketAttributeResponse::FileAttachable
  include MarketAttributeResponse::JsonValidatable

  store_accessor :value

  validates :documents, presence: { message: I18n.t('activerecord.errors.json_schema.required') }

  def self.json_schema_properties
    ['files']
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :documents
  end
end
