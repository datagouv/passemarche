# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  wrap_parameters false
  before_action :require_admin_role!, only: %i[new create edit update reorder archive import]
  before_action :load_form_data, only: %i[new create edit update]

  def index
    @market_attributes = MarketAttributeQueryService.call(filters: filter_params)
    @stats = SocleDeBaseStatsService.call
    @categories = Category.active.ordered
    @market_types = MarketType.active
  end

  def show
    load_market_attribute
    @presenter = SocleDeBasePresenter.new(@market_attribute)
  end

  def new
    @market_attribute = MarketAttribute.new
  end

  def edit
    load_market_attribute
    @presenter = SocleDeBasePresenter.new(@market_attribute)
    prefill_from_presenter
  end

  def create
    service = MarketAttributeCreationService.new(params: creation_params)
    service.perform

    if service.success?
      redirect_to admin_socle_de_base_index_path, notice: t('.success')
    else
      assign_creation_failure_state(service)
      render :new, status: :unprocessable_content
    end
  end

  def update
    load_market_attribute
    service = MarketAttributeUpdateService.new(
      market_attribute: @market_attribute,
      params: market_attribute_params
    )
    service.perform

    if service.success?
      redirect_to admin_socle_de_base_path(@market_attribute), notice: t('.success')
    else
      assign_update_failure_state(service)
      render :edit, status: :unprocessable_content
    end
  end

  def reorder
    ordered_ids = params.require(:ordered_ids)

    MarketAttribute.transaction do
      ordered_ids.each_with_index do |id, index|
        MarketAttribute.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end

  def import
    csv_file = params.dig(:socle_de_base, :csv_file)

    return redirect_to admin_socle_de_base_index_path, alert: t('.no_file') unless csv_file

    import_csv(csv_file)
  end

  def archive
    attribute = MarketAttribute.find(params[:id])

    if MarketAttributeArchiveService.call(market_attribute: attribute)
      redirect_to admin_socle_de_base_index_path,
        notice: t('.success', key: attribute.key)
    else
      redirect_to admin_socle_de_base_index_path,
        alert: t('.already_archived')
    end
  end

  def export
    attributes = MarketAttributeQueryService.call(filters: filter_params)
    service = ExportSocleDeBaseCsvService.new(market_attributes: attributes)
    service.perform

    send_data service.result[:csv_data],
      filename: service.result[:filename],
      type: 'text/csv; charset=utf-8'
  end

  private

  def assign_creation_failure_state(service)
    @market_attribute = service.result || MarketAttribute.new
    @submitted_market_type_ids = sanitized_market_type_ids(creation_params)
    @errors = service.errors
  end

  def assign_update_failure_state(service)
    @market_attribute.configuration_mode = market_attribute_params[:configuration_mode]
    @presenter = SocleDeBasePresenter.new(@market_attribute)
    @errors = service.errors
  end

  def sanitized_market_type_ids(permitted_params)
    permitted_params[:market_type_ids]&.compact_blank&.map(&:to_i) || []
  end

  def load_market_attribute
    @market_attribute = MarketAttribute.includes(:market_types, :subcategory).find(params[:id])
  end

  def load_form_data
    @categories = Category.active.ordered
    @subcategories = Subcategory.active.ordered.includes(:category)
    @market_types = MarketType.active
    @input_types = MarketAttribute.input_types.keys
    @subcategories_json = build_subcategories_json
    @api_keys_by_name = build_api_keys_by_name
    @input_type_hints = @input_types.index_with do |t|
      I18n.t("admin.socle_de_base.input_type_hints.#{t}", default: nil)
    end.compact
  end

  def build_subcategories_json
    @subcategories.map do |s|
      { id: s.id, categoryId: s.category_id, buyerLabel: s.buyer_label, candidateLabel: s.candidate_label }
    end
  end

  def build_api_keys_by_name
    MarketAttribute.where.not(api_name: nil)
      .distinct.pluck(:api_name, :api_key)
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last).uniq.sort }
  end

  def prefill_from_presenter
    resolve_subcategory_id
    @market_attribute.buyer_name ||= @presenter.buyer_name
    @market_attribute.buyer_description ||= @presenter.buyer_description
    @market_attribute.candidate_name ||= @presenter.candidate_name
    @market_attribute.candidate_description ||= @presenter.candidate_description
  end

  def resolve_subcategory_id
    return if @market_attribute.subcategory_id.present?
    return if @market_attribute.subcategory_key.blank?

    subcategory = Subcategory.find_by(key: @market_attribute.subcategory_key)
    @market_attribute.subcategory_id = subcategory&.id
  end

  def import_csv(csv_file)
    result = ImportSocleDeBaseCsvService.call(csv_file: csv_file.tempfile)

    if result.success?
      redirect_to admin_socle_de_base_index_path, notice: format_statistics(result.statistics)
    else
      redirect_to admin_socle_de_base_index_path, alert: t('.error', message: result.errors.join(', '))
    end
  end

  def format_statistics(stats)
    t('admin.socle_de_base.import.success',
      created: stats[:created],
      updated: stats[:updated],
      soft_deleted: stats[:soft_deleted],
      skipped: stats[:skipped])
  end

  def filter_params
    params.permit(:query, :category, :source, :market_type_id).to_h.symbolize_keys
  end

  def creation_params
    params.expect(market_attribute: [
      :input_type, :mandatory, :configuration_mode,
      :subcategory_id,
      :api_name, :api_key,
      :buyer_name, :candidate_name,
      :buyer_description, :candidate_description,
      { market_type_ids: [] }
    ])
  end

  def market_attribute_params
    params.expect(market_attribute: [
      :input_type, :mandatory, :subcategory_id, :category_key, :subcategory_key,
      :api_name, :api_key, :configuration_mode,
      :buyer_name, :buyer_description, :candidate_name, :candidate_description,
      { market_type_ids: [] }
    ])
  end
end
