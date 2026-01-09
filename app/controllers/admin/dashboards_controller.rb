# frozen_string_literal: true

class Admin::DashboardsController < Admin::ApplicationController
  before_action :set_editor, only: %i[show export]
  before_action :load_editors_for_filter

  def show
    result = Admin::CalculateDashboardStatistics.call(editor: @editor)
    @presenter = Admin::DashboardPresenter.new(
      statistics: result.statistics,
      editor: @editor
    )
  end

  def export
    result = Admin::CalculateDashboardStatistics.call(editor: @editor)
    export_result = Admin::ExportDashboardStatistics.call(
      statistics: result.statistics,
      editor: @editor
    )

    send_data export_result.csv_data,
      filename: export_result.filename,
      type: 'text/csv; charset=utf-8'
  end

  private

  def set_editor
    return if params[:editor_id].blank?

    @editor = Editor.find_by(id: params[:editor_id])
  end

  def load_editors_for_filter
    @editors = Editor.authorized_and_active.order(:name)
  end
end
