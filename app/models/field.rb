# frozen_string_literal: true

class Field
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :key, :string
  attribute :type, :string
  attribute :category, :string
  attribute :subcategory, :string
  attribute :source_type, :string
  attribute :required_for, default: -> { [] }
  attribute :optional_for, default: -> { [] }
  attribute :defense_required, :boolean, default: false
  attribute :defense_optional, :boolean, default: false

  validates :key, :type, :category, :subcategory, :source_type, presence: true
  validates :type, inclusion: { in: %w[document_upload text_field checkbox_field] }
  validates :source_type, inclusion: { in: %w[authentic_source honor_declaration] }

  def required_for_market_type?(market_type)
    required_for.include?(market_type.to_s)
  end

  def optional_for_market_type?(market_type)
    optional_for.include?(market_type.to_s)
  end

  def required_for_defense?
    defense_required
  end

  def optional_for_defense?
    defense_optional
  end

  def source_info
    @source_info ||= I18n.t("form_fields.source_types.#{source_type}")
  end

  def localized_name
    @localized_name ||= I18n.t("form_fields.fields.#{key}.name")
  end

  def localized_description
    @localized_description ||= I18n.t("form_fields.fields.#{key}.description")
  end

  def localized_category
    @localized_category ||= I18n.t("form_fields.categories.#{category}")
  end

  def localized_subcategory
    @localized_subcategory ||= I18n.t("form_fields.subcategories.#{subcategory}")
  end

  def document_upload?
    type == 'document_upload'
  end

  def text_field?
    type == 'text_field'
  end

  def checkbox_field?
    type == 'checkbox_field'
  end

  def authentic_source?
    source_type == 'authentic_source'
  end

  def honor_declaration?
    source_type == 'honor_declaration'
  end
end
