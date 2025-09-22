class MarketAttributeResponse::CheckboxWithDocument < MarketAttributeResponse::Checkbox
  include MarketAttributeResponse::FileAttachable

  validate :checkbox_and_documents_consistency

  def self.json_schema_properties
    %w[checked files]
  end

  def self.json_schema_required
    ['checked']
  end

  def self.json_schema_error_field
    :checked
  end

  private

  def checkbox_and_documents_consistency
    return unless !checked_as_boolean && documents.attached?

    errors.add(:documents, :document_not_allowed_unless_checked)
  end
end
