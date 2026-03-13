# frozen_string_literal: true

module ApplicationHelper
  def format_paris_time(datetime, format = '%d/%m/%Y à %H:%M')
    return '-' if datetime.nil?

    # Convert to Paris timezone - Rails will handle this automatically with Time.zone
    datetime.in_time_zone('Europe/Paris').strftime(format)
  end

  def page_break_class(context, index)
    'page-break-before' if index.positive? && context.in?(%i[pdf buyer])
  end

  def non_production_environment?
    !Rails.env.production?
  end
end
