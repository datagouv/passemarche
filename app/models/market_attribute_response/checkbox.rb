class MarketAttributeResponse::Checkbox < MarketAttributeResponse
  store_accessor :value, :checked

  def checked=(val)
    super(ActiveModel::Type::Boolean.new.cast(val))
  end

  validates :checked, inclusion: { in: [true, false], message: :invalid }
  validate :checked_field_required
  validate :checked_additional_properties_valid

  protected

  def checked_as_boolean
    ActiveModel::Type::Boolean.new.cast(checked)
  end

  private

  def checked_field_required
    return unless value.blank? || !value.key?('checked')

    errors.add(:checked, I18n.t('activerecord.errors.json_schema.required'))
  end

  def checked_additional_properties_valid
    return if value.blank?

    allowed_keys = ['checked']
    extra_keys = value.keys - allowed_keys

    return if extra_keys.empty?

    errors.add(:checked, I18n.t('activerecord.errors.json_schema.additional_properties'))
  end
end
