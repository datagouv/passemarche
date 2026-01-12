# frozen_string_literal: true

class Admin::DashboardPresenter
  CARD_KEYS = %i[
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

  def initialize(statistics:, editor: nil)
    @statistics = statistics
    @editor = editor
  end

  attr_reader :statistics, :editor

  def scoped?
    editor.present?
  end

  def page_title
    if scoped?
      I18n.t('admin.dashboard.title_with_editor', editor_name: editor.name)
    else
      I18n.t('admin.dashboard.title')
    end
  end

  def formatted_completion_time
    format_duration(statistics[:avg_completion_time_seconds])
  end

  def auto_fill_percentage
    rate = statistics[:auto_fill_rate]
    return 'N/A' if rate.nil?

    ActionController::Base.helpers.number_to_percentage(rate * 100, precision: 1)
  end

  def statistics_cards
    CARD_KEYS.map do |key|
      { key:, value: value_for_card(key) }
    end
  end

  private

  def value_for_card(key)
    case key
    when :avg_completion_time
      formatted_completion_time
    when :auto_fill_rate
      auto_fill_percentage
    else
      statistics[key]
    end
  end

  def format_duration(seconds)
    return 'N/A' if seconds.nil? || seconds.zero?

    total_hours = (seconds / 3600).to_i
    total_minutes = ((seconds % 3600) / 60).to_i

    "#{total_hours}h#{total_minutes}min"
  end
end
