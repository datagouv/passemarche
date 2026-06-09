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

  MARKET_TYPE_CONFIGS = {
    'works' => { icon: 'icon-travaux.svg', icon_only: 'icon-travaux-only.svg', bg: '#FEEBD0' },
    'services' => { icon: 'icon-services.svg', icon_only: 'icon-services-only.svg', bg: '#FEE7FC' }
  }.freeze

  def market_type_icon_tag(market_type_codes)
    code = market_type_codes.first
    config = MARKET_TYPE_CONFIGS[code]
    return unless config

    image_tag config[:icon], alt: '', aria: { hidden: true }, width: 36, height: 36, class: 'market-type-icon'
  end

  def market_type_badge_tag(code, label, background: nil)
    config = MARKET_TYPE_CONFIGS[code]
    bg = background || config&.dig(:bg)
    style = bg ? "background-color:#{bg};" : nil
    if config
      icon = image_tag(config[:icon_only], alt: '', aria: { hidden: true }, width: 16, height: 16)
      content_tag(:span, icon + label, class: 'market-type-badge', style:)
    else
      content_tag(:span, label, class: 'market-type-badge', style:)
    end
  end
end
