# frozen_string_literal: true

require 'csv'

class ImportSocleDeBaseCsvService < ApplicationService
  Result = Struct.new(:success, :statistics, :errors, keyword_init: true) do
    alias_method :success?, :success
  end

  COLUMN = {
    key: 'Clé',
    category_key: 'Catégorie (clé)',
    subcategory_key: 'Sous-catégorie (clé)',
    buyer_category: 'Catégorie acheteur',
    buyer_subcategory: 'Sous-catégorie acheteur',
    buyer_name: 'Nom acheteur',
    buyer_description: 'Description acheteur',
    candidate_category: 'Catégorie candidat',
    candidate_subcategory: 'Sous-catégorie candidat',
    candidate_name: 'Nom candidat',
    candidate_description: 'Description candidat',
    mandatory: 'Obligatoire',
    api_name: 'Source (api_name)',
    api_key: 'Clé API',
    input_type: 'Type de saisie',
    position: 'Position',
    market_types: 'Types de marché'
  }.freeze

  def initialize(csv_file:)
    @csv_file = csv_file
    @statistics = { created: 0, updated: 0, soft_deleted: 0, skipped: 0 }
    @errors = []
    @imported_keys = []
    @category_cache = {}
    @subcategory_cache = {}
  end

  def call
    validate_file!
    return build_result unless @errors.empty?

    rows = parse_csv
    return build_result unless @errors.empty?

    import_rows(rows)
    soft_delete_missing
    build_result
  end

  private

  def validate_file!
    path = resolve_path
    @errors << 'Fichier introuvable' unless path && File.exist?(path)
  end

  def resolve_path
    case @csv_file
    when String, Pathname then @csv_file.to_s
    else @csv_file.respond_to?(:path) ? @csv_file.path : nil
    end
  end

  def parse_csv
    CSV.read(resolve_path, headers: true, col_sep: ';', liberal_parsing: true)
  rescue CSV::MalformedCSVError => e
    @errors << "CSV invalide : #{e.message}"
    []
  end

  def import_rows(rows)
    ActiveRecord::Base.transaction do
      rows.each_with_index { |row, index| import_single_row(row, index + 2) }
    end
  end

  def import_single_row(row, line_number)
    key = col(row, :key)
    return @statistics[:skipped] += 1 if key.blank?

    persist_row(row, key)
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Ligne #{line_number} (#{key}) : #{e.message}"
    @statistics[:skipped] += 1
  end

  def persist_row(row, key)
    attribute = MarketAttribute.find_or_initialize_by(key:)
    was_new = attribute.new_record?

    subcategory = find_or_create_subcategory(row)
    assign_attribute_fields(attribute, row, subcategory)
    attribute.save!
    assign_market_types(attribute, row)

    @imported_keys << key
    track_stats(was_new, attribute.saved_changes.present?)
  end

  def find_or_create_category(row)
    key = col(row, :category_key)
    @category_cache[key] ||= persist_category(row, key)
  end

  def persist_category(row, key)
    category = Category.find_or_initialize_by(key:)
    category.buyer_label = col(row, :buyer_category).presence || category.buyer_label
    category.candidate_label = col(row, :candidate_category).presence || category.candidate_label
    category.position ||= Category.maximum(:position).to_i + 1
    category.save!
    category
  end

  def find_or_create_subcategory(row)
    cache_key = [col(row, :category_key), col(row, :subcategory_key)]
    @subcategory_cache[cache_key] ||= persist_subcategory(row)
  end

  def persist_subcategory(row)
    category = find_or_create_category(row)
    subcategory = Subcategory.find_or_initialize_by(category:, key: col(row, :subcategory_key))
    update_subcategory_labels(subcategory, row)
    subcategory.save!
    subcategory
  end

  def update_subcategory_labels(subcategory, row)
    subcategory.buyer_label = col(row, :buyer_subcategory).presence || subcategory.buyer_label
    subcategory.candidate_label = col(row, :candidate_subcategory).presence || subcategory.candidate_label
    subcategory.position ||= Subcategory.maximum(:position).to_i + 1
  end

  def assign_attribute_fields(attribute, row, subcategory)
    attribute.assign_attributes(
      category_key: col(row, :category_key),
      subcategory_key: col(row, :subcategory_key),
      subcategory:,
      buyer_name: col(row, :buyer_name),
      buyer_description: col(row, :buyer_description),
      candidate_name: col(row, :candidate_name),
      candidate_description: col(row, :candidate_description),
      mandatory: col(row, :mandatory) == 'Oui',
      api_name: col(row, :api_name).presence,
      api_key: col(row, :api_key).presence,
      input_type: col(row, :input_type),
      position: col(row, :position)&.to_i
    )
  end

  def assign_market_types(attribute, row)
    raw = row[COLUMN[:market_types]].to_s
    codes = raw.split(',').map(&:strip).compact_blank
    attribute.market_types.clear

    codes.each do |code|
      market_type = MarketType.find_by(code:)
      attribute.market_types << market_type if market_type
    end
  end

  def soft_delete_missing
    # rubocop:disable Rails/SkipsModelValidations
    deleted_count = MarketAttribute
      .where.not(key: @imported_keys)
      .where(deleted_at: nil)
      .update_all(deleted_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations

    @statistics[:soft_deleted] = deleted_count
  end

  def track_stats(was_new, was_changed)
    if was_new
      @statistics[:created] += 1
    elsif was_changed
      @statistics[:updated] += 1
    end
  end

  def build_result
    Result.new(success: @errors.empty?, statistics: @statistics, errors: @errors)
  end

  def col(row, name)
    row[COLUMN[name]]&.strip
  end
end
