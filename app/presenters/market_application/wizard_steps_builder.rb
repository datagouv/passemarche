# frozen_string_literal: true

class MarketApplication::WizardStepsBuilder
  INITIAL_STEPS = %i[api_data_recovery_status market_information].freeze
  FINAL_STEP = :summary
  ATTESTATION_STEP = :attestation_motifs_exclusion

  def initialize(market_application:, visible_attributes:, selected_lot_types:)
    @market_application = market_application
    @visible_attributes = visible_attributes
    @selected_lot_types = selected_lot_types
  end

  def wizard_steps
    steps = INITIAL_STEPS + scoped_subcategory_keys + [FINAL_STEP]
    inject_attestation_step(steps.uniq)
  end

  # Étapes visuelles du stepper — toujours des groupes logiques
  # Mono-type : catégories du marché + summary
  # Multi-type : première sous-cat de chaque scope + summary (affiché sur la page lot_selection)
  def stepper_steps
    inject_attestation_step(stepper_group_keys + [FINAL_STEP])
  end

  # Étapes stepper contextuelles pour un scope donné
  # Utilisé dans le wizard multi-type : chaque scope a son propre stepper
  # Structure : INITIAL_STEPS + catégories du scope + FINAL_STEP
  def stepper_steps_for_scope(scope)
    return stepper_steps unless multi_type?

    scope_category_keys = category_keys_for_scope(scope)
    inject_attestation_step((INITIAL_STEPS + scope_category_keys + [FINAL_STEP]).uniq)
  end

  # Mappe une étape wizard vers son groupe dans le stepper contextuel du scope
  def stepper_step_for(step, scope = nil)
    step = step.to_sym
    steps = scope ? stepper_steps_for_scope(scope) : stepper_steps
    return step if steps.include?(step)

    step_to_stepper_group_for_scope(step, scope)
  end

  def scope_for_step(step)
    return nil unless multi_type?

    scopes.find { |_scope, keys| keys.include?(step.to_sym) }&.first
  end

  def subcategory_keys_for_scope(scope)
    scopes.fetch(scope, [])
  end

  def active_scopes
    scopes.keys
  end

  def multi_type?
    @market_application.multi_type_selected_lots?
  end

  private

  def scopes
    @scopes ||= build_scopes
  end

  def build_scopes
    return default_scope unless multi_type?

    result = { commun: attributes_for_scope(:commun) }
    @selected_lot_types.each do |type|
      keys = attributes_for_scope(type.code.to_sym)
      result[type.code.to_sym] = keys if keys.any?
    end
    result.reject { |_, keys| keys.empty? }
  end

  def default_scope
    { default: default_subcategory_keys }
  end

  def default_subcategory_keys
    @visible_attributes
      .filter_map(&:subcategory_key)
      .uniq
      .map(&:to_sym)
  end

  def scoped_subcategory_keys
    scopes.flat_map { |_, keys| keys }
  end

  # En mono-type : catégories (identite_entreprise, capacite_technique...)
  # En multi-type : première sous-catégorie de chaque scope (représente le groupe)
  def stepper_group_keys
    return category_keys.map(&:to_sym) unless multi_type?

    scopes.filter_map { |_, keys| keys.first }
  end

  # Catégories distinctes des attributs d'un scope
  def category_keys_for_scope(scope)
    subcategory_keys = subcategory_keys_for_scope(scope).map(&:to_s)
    @visible_attributes
      .select { |attr| subcategory_keys.include?(attr.subcategory_key) }
      .filter_map(&:category_key)
      .uniq
      .map(&:to_sym)
  end

  # Mappe une sous-catégorie vers sa catégorie parente (groupe stepper mono-type)
  # ou vers la sous-catégorie elle-même si déjà un groupe stepper (multi-type)
  def step_to_stepper_group_for_scope(step, scope)
    fixed = { ATTESTATION_STEP => ATTESTATION_STEP, FINAL_STEP => FINAL_STEP }
    return fixed[step] if fixed.key?(step)

    if scope
      step
    else
      subcategory_to_category_mapping[step]
    end
  end

  def subcategory_to_category_mapping
    @subcategory_to_category_mapping ||= fixed_step_mapping.merge(category_subcategory_mapping)
  end

  def fixed_step_mapping
    mapping = {}
    INITIAL_STEPS.each { |s| mapping[s] = s }
    mapping[ATTESTATION_STEP] = ATTESTATION_STEP
    mapping[FINAL_STEP] = FINAL_STEP
    mapping
  end

  def category_subcategory_mapping
    category_keys.each_with_object({}) do |cat_key, mapping|
      cat_sym = cat_key.to_sym
      mapping[cat_sym] = cat_sym
      @visible_attributes
        .select { |attr| attr.category_key == cat_key }
        .filter_map(&:subcategory_key).uniq
        .each { |sub| mapping[sub.to_sym] = cat_sym }
    end
  end

  def attributes_for_scope(scope)
    type_ids = @selected_lot_types.map(&:id)
    return [] if type_ids.empty?

    attrs = scope == :commun ? common_attributes(type_ids) : type_specific_attributes(scope, type_ids)
    attrs.filter_map(&:subcategory_key).uniq.map(&:to_sym)
  end

  def common_attributes(type_ids)
    @visible_attributes.select do |attr|
      (type_ids & attr.market_types.map(&:id)).size > 1
    end
  end

  def type_specific_attributes(scope, type_ids)
    target = @selected_lot_types.find { |t| t.code == scope.to_s }
    return [] unless target

    @visible_attributes.select do |attr|
      attr_type_ids = attr.market_types.map(&:id)
      attr_type_ids.include?(target.id) && (type_ids & attr_type_ids).size == 1
    end
  end

  def category_keys
    @visible_attributes.filter_map(&:category_key).uniq
  end

  def inject_attestation_step(steps)
    idx = steps.find_index { |s| s.to_s.start_with?('motifs_exclusion') }
    return steps unless idx

    steps.insert(idx, ATTESTATION_STEP)
    steps
  end
end
