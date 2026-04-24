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

  MARKET_TYPE_ICONS = {
    'works' => 'icon-travaux.png'
  }.freeze

  def market_type_icon_tag(market_type_codes)
    code = market_type_codes.first
    icon = MARKET_TYPE_ICONS[code]
    return unless icon

    image_tag icon, alt: '', aria: { hidden: true }, width: 36, height: 36
  end
end
