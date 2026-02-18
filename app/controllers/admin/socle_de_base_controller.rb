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

  def reorder
    ordered_ids = params.require(:ordered_ids)

    MarketAttribute.transaction do
      ordered_ids.each_with_index do |id, index|
        MarketAttribute.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end

  def create
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

  private

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
end
