# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  wrap_parameters false
  before_action :require_admin_role!, only: [:reorder]

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

  def edit
    load_market_attribute
    load_form_data
  end

  def create
    csv_file = params.dig(:socle_de_base, :csv_file)

    return redirect_to admin_socle_de_base_index_path, alert: t('.no_file') unless csv_file

    import_csv(csv_file)
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
      load_form_data
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

  private

  def load_market_attribute
    @market_attribute = MarketAttribute.includes(:market_types, :subcategory).find(params[:id])
  end

  def load_form_data
    @categories = Category.active.ordered
    @subcategories = Subcategory.active.ordered.includes(:category)
    @market_types = MarketType.active
    @input_types = MarketAttribute.input_types.keys
  end

  def filter_params
    params.permit(:query, :category, :source, :market_type_id).to_h.symbolize_keys
  end

  def import_csv(csv_file)
    result = FieldConfigurationImport.call(csv_file_path: csv_file.tempfile.path)

    if result.success?
      redirect_to admin_socle_de_base_index_path, notice: format_statistics(result.statistics)
    else
      redirect_to admin_socle_de_base_index_path, alert: t('.error', message: result.message)
    end
  end

  def format_statistics(stats)
    t('.success',
      created: stats[:created],
      updated: stats[:updated],
      soft_deleted: stats[:soft_deleted],
      skipped: stats[:skipped])
  end

  def market_attribute_params
    params.expect(market_attribute: [
      :input_type, :mandatory, :subcategory_id, :category_key, :subcategory_key,
      :api_name, :api_key,
      { market_type_ids: [] }
    ])
  end
end
