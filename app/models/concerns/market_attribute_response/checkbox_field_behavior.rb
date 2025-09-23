# frozen_string_literal: true

module MarketAttributeResponse::CheckboxFieldBehavior
  extend ActiveSupport::Concern

  included do
    validates :checked, inclusion: { in: [true, false], message: :invalid }
    validate :checked_value_must_be_boolean
  end

  def checked=(val)
    casted_val = cast_to_boolean(val)
    self.value = if casted_val.nil?
                   (value || {}).except('checked')
                 else
                   (value || {}).merge('checked' => casted_val)
                 end
  end

  def checked
    cast_to_boolean((value || {})['checked'])
  end

  def checked?
    checked
  end

  protected

  def checked_as_boolean
    cast_to_boolean(checked)
  end

  private

  def checked_value_must_be_boolean
    return if value.blank? || !value.key?('checked')

    raw_checked = value['checked']
    return if raw_checked.is_a?(TrueClass) || raw_checked.is_a?(FalseClass)

    errors.add(:checked, :invalid)
  end

  def cast_to_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
