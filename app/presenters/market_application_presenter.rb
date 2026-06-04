# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class MarketApplicationPresenter
  include SidemenuHelper
  include MarketPresenterConcern

  delegate :name, :siret, to: :public_market, prefix: :market
  delegate :attestation, to: :@market_application
  delegate :attached?, to: :attestation, prefix: true
  delegate :multi_type_selected_lots?, to: :@market_application
  delegate :wizard_steps, :stepper_steps, :stepper_step_for, :stepper_steps_for_scope,
    :scope_for_step, :subcategory_keys_for_scope, :active_scopes, :attributes_for_scope,
    to: :wizard_steps_builder

  MARKET_INFO_PARENT_CATEGORY = 'identite_entreprise'

  def initialize(market_application)
    @market_application = market_application
  end

  def fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes)
  end

  def category_keys_with_attestation_motifs_exclusion
    category_keys_for_stepper.dup.tap do |steps|
      inject_attestation_motifs_exclusion_step(steps)
    end
  end

  def parent_category_for(subcategory_key)
    return nil if subcategory_key.blank?
    return MARKET_INFO_PARENT_CATEGORY if subcategory_key.to_s == 'market_information'

    all_market_attributes
      .find { |attr| attr.subcategory_key == subcategory_key.to_s }
      &.category_key
  end

  def subcategories_for_category(category_key)
    return [] if category_key.blank?

    subcategories = []
    subcategories << 'market_information' if category_key == MARKET_INFO_PARENT_CATEGORY

    category_subcategories = all_market_attributes
      .select { |attr| attr.category_key == category_key.to_s }
      .filter_map(&:subcategory_key)
      .uniq

    subcategories + category_subcategories
  end

  def market_attributes_for_subcategory(category_key, subcategory_key)
    return [] if category_key.blank? || subcategory_key.blank?

    all_market_attributes.select do |attr|
      attr.category_key == category_key.to_s && attr.subcategory_key == subcategory_key.to_s
    end
  end

  def market_attribute_response_for(market_attribute)
    responses_by_attribute_id[market_attribute.id] ||= @market_application.market_attribute_responses.build(
      market_attribute:,
      type: MarketAttributeResponse.type_from_input_type(market_attribute.input_type)
    )
  end

  def response_component_class(response)
    return nil if response&.type.blank?

    "MarketAttributeResponse::#{response.type}Component".constantize
  rescue NameError
    nil
  end

  def submitted_at
    @market_application.completed_at
  end

  # === LOTS METHODS ===

  def lots_by_effective_type
    @lots_by_effective_type ||= selected_lots.group_by(&:effective_market_type)
  end

  def selected_lot_types
    @selected_lot_types ||= @market_application.selected_lot_types
  end

  def lots_by_type_sorted
    @lots_by_type_sorted ||= public_market.lots.ordered
      .includes(:market_type, :platform_market_type)
      .group_by(&:effective_market_type)
  end

  def selected_lots
    @selected_lots ||= @market_application.lots.sort_by(&:position)
  end

  def public_market_lots
    @public_market_lots ||= public_market.lots.ordered.to_a
  end

  def public_market_has_lots?
    public_market_lots.any?
  end

  # === RESPONSE METHODS (with hidden filtering) ===

  def responses_for_subcategory(category_key, subcategory_key)
    return [] if category_key.blank? || subcategory_key.blank?

    market_attributes_for_subcategory(category_key, subcategory_key)
      .map { |attr| market_attribute_response_for(attr) }
      .reject(&:hidden?)
  end

  def responses_for_category(category_key)
    return [] if category_key.blank?

    all_market_attributes
      .select { |attr| attr.category_key == category_key.to_s }
      .map { |attr| market_attribute_response_for(attr) }
      .reject(&:hidden?)
  end

  def responses_grouped_by_subcategory(category_key)
    return {} if category_key.blank?

    responses_for_category(category_key).group_by { |r| r.market_attribute.subcategory_key }
  end

  # === LOT SELECTION ===

  def lots_saved?
    selected_lots.any?
  end

  def form_started?
    responses_by_attribute_id.any?
  end

  def lot_type_label(lot)
    code = lot.effective_market_type&.code || public_market.market_type_codes.first
    code.present? ? I18n.t("market_types.#{code}", default: code.humanize) : nil
  end

  def cta_translation_key
    form_started? ? 'candidate.lot_selection.modify' : 'candidate.lot_selection.start'
  end

  # === PROGRESS METHODS ===

  def total_fields_count
    visible_market_attributes.size
  end

  def filled_fields_count
    visible_market_attributes.count do |attr|
      response = responses_by_attribute_id[attr.id]
      response_has_data?(response)
    end
  end

  def fields_complete?
    total_fields_count.positive? && filled_fields_count == total_fields_count
  end

  def total_fields_count_for_scope(scope)
    attributes_for_scope_as_market_attributes(scope).size
  end

  def filled_fields_count_for_scope(scope)
    attributes_for_scope_as_market_attributes(scope).count do |attr|
      response_has_data?(responses_by_attribute_id[attr.id])
    end
  end

  def scope_complete?(scope)
    total = total_fields_count_for_scope(scope)
    total.positive? && filled_fields_count_for_scope(scope) == total
  end

  def all_scopes_complete?
    active_scopes.all? { |scope| scope_complete?(scope) }
  end

  def first_step_for_scope(scope)
    subcategory_keys_for_scope(scope).first || :api_data_recovery_status
  end

  def lots_count_for_scope(scope)
    return selected_lots.size if scope == :commun

    selected_lots.count { |lot| lot.effective_market_type&.code == scope.to_s }
  end

  def market_type_codes_for_scope(scope)
    return selected_lot_types.map(&:code) if scope == :commun

    [scope.to_s]
  end

  # === VALIDATION METHODS ===

  def optional_market_attributes?
    public_market.market_attributes.exists?(mandatory: false)
  end

  def missing_mandatory_motifs_exclusion?
    mandatory_motifs_exclusion_attributes.any? do |attr|
      response = market_attribute_response_for(attr)
      !response_has_data?(response)
    end
  end

  private

  def attributes_for_scope_as_market_attributes(scope)
    scope_keys = subcategory_keys_for_scope(scope).map(&:to_s)
    visible_market_attributes.select { |attr| scope_keys.include?(attr.subcategory_key) }
  end

  def wizard_steps_builder
    @wizard_steps_builder ||= MarketApplication::WizardStepsBuilder.new(
      market_application: @market_application,
      visible_attributes: visible_market_attributes,
      selected_lot_types:
    )
  end

  def public_market
    @public_market ||= @market_application.public_market
  end

  def market_type_codes
    public_market.market_type_codes
  end

  def mandatory_motifs_exclusion_attributes
    public_market.market_attributes
      .where(mandatory: true)
      .where('category_key LIKE ?', 'motifs_exclusion%')
  end

  def response_has_data?(response)
    return false if response.nil? || response.new_record?

    has_documents = response.respond_to?(:documents) && response.documents.attached?
    has_value = response.value.any? { |_, v| v.present? }

    has_documents || has_value
  end

  def responses_by_attribute_id
    @responses_by_attribute_id ||= @market_application.market_attribute_responses.index_by(&:market_attribute_id)
  end

  def all_market_attributes
    @all_market_attributes ||= public_market.market_attributes.sort_by(&:position)
  end

  def hidden_attr_ids
    @hidden_attr_ids ||= @market_application.market_attribute_responses
      .where(hidden: true)
      .pluck(:market_attribute_id)
  end

  def visible_market_attributes
    @visible_market_attributes ||= all_market_attributes.reject { |attr| hidden_attr_ids.include?(attr.id) }
  end

  def organize_fields_by_category_and_subcategory(market_attributes)
    category_keys.each_with_object({}) do |category_key, result|
      category_attrs = market_attributes.select { |attr| attr.category_key == category_key }
      result[category_key] = group_by_subcategory(category_attrs) if category_attrs.any?
    end
  end

  def category_keys
    @category_keys ||= all_market_attributes.filter_map(&:category_key).uniq
  end

  def category_keys_for_stepper
    category_keys.map(&:to_sym)
  end

  def inject_attestation_motifs_exclusion_step(steps)
    first_exclusion_index = steps.find_index { |s| s.to_s.start_with?('motifs_exclusion') }
    return steps unless first_exclusion_index

    steps.insert(first_exclusion_index, MarketApplication::WizardStepsBuilder::ATTESTATION_STEP)
    steps
  end
end
# rubocop:enable Metrics/ClassLength
