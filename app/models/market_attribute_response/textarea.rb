class MarketAttributeResponse::Textarea < MarketAttributeResponse::TextInput
  validate :textarea_text_required_for_manual_fields

  private

  def textarea_text_required_for_manual_fields
    return if text.present?
    return if auto? # Skip validation for auto-filled fields

    errors.add(:text, I18n.t('activerecord.errors.json_schema.required'))
  end
end
