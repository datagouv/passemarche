# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    @market_attributes = MarketAttribute.active.ordered.includes(:market_types)
    @stats = SocleDeBaseStatsService.call
  end

  def create
    csv_file = params.dig(:socle_de_base, :csv_file)

    return redirect_to admin_socle_de_base_index_path, alert: t('.no_file') unless csv_file

    import_csv(csv_file)
  end

  private

  def import_csv(csv_file)
    service = FieldConfigurationImportService.new(csv_file_path: csv_file.tempfile.path)
    service.perform

    if service.success?
      redirect_to admin_socle_de_base_index_path, notice: format_statistics(service.result)
    else
      redirect_to admin_socle_de_base_index_path, alert: t('.error', message: error_messages(service))
    end
  end

  def format_statistics(stats)
    t('.success',
      created: stats[:created],
      updated: stats[:updated],
      soft_deleted: stats[:soft_deleted],
      skipped: stats[:skipped])
  end

  def error_messages(service)
    service.errors.each_value.flat_map(&:itself).join(', ')
  end
end
