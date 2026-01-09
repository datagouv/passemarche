# frozen_string_literal: true

require 'csv'

class Admin::ExportDashboardStatistics < ApplicationInteractor
  # Keys that only make sense for global statistics (not filtered by editor)
  GLOBAL_ONLY_KEYS = %i[editors_total editors_active].freeze

  # All card keys used for translations (same as presenter)
  ALL_CARD_KEYS = %i[
    editors_total
    editors_active
    markets_total
    markets_completed
    markets_active
    applications_total
    applications_completed
    documents_transmitted
    unique_companies
    unique_buyers
    avg_completion_time
    auto_fill_rate
  ].freeze

  def call
    context.csv_data = generate_csv
    context.filename = generate_filename
  end

  private

  def generate_csv
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << headers
      metric_rows.each { |row| csv << row }
    end
  end

  def headers
    [
      I18n.t('admin.dashboard.export.headers.metric'),
      I18n.t('admin.dashboard.export.headers.value'),
      I18n.t('admin.dashboard.export.headers.export_date'),
      I18n.t('admin.dashboard.export.headers.editor')
    ]
  end

  def metric_rows
    export_keys.map do |key|
      [
        metric_label(key),
        format_value(key),
        export_date,
        editor_name
      ]
    end
  end

  def export_keys
    return ALL_CARD_KEYS unless context.editor

    ALL_CARD_KEYS - GLOBAL_ONLY_KEYS
  end

  def metric_label(key)
    I18n.t("admin.dashboard.cards.#{key}.title")
  end

  def format_value(key)
    case key
    when :avg_completion_time
      format_duration(context.statistics[:avg_completion_time_seconds])
    when :auto_fill_rate
      format_percentage(context.statistics[:auto_fill_rate])
    else
      context.statistics[key].to_s
    end
  end

  def format_duration(seconds)
    return 'N/A' if seconds.nil? || seconds.zero?

    minutes = (seconds / 60).to_i
    remaining_seconds = (seconds % 60).to_i

    return format_hours_and_minutes(minutes) if minutes > 60
    return "#{minutes}min #{remaining_seconds}s" if minutes.positive?

    "#{remaining_seconds}s"
  end

  def format_hours_and_minutes(minutes)
    hours = minutes / 60
    remaining_minutes = minutes % 60
    "#{hours}h #{remaining_minutes}min"
  end

  def format_percentage(rate)
    return 'N/A' if rate.nil?

    "#{(rate * 100).round(1)}%"
  end

  def export_date
    I18n.l(Date.current, format: :default)
  end

  def editor_name
    context.editor&.name || I18n.t('admin.dashboard.export.all_editors')
  end

  def generate_filename
    editor_suffix = context.editor&.name&.parameterize || 'global'
    "#{I18n.t('admin.dashboard.export.filename')}-#{editor_suffix}-#{Date.current}.csv"
  end
end
