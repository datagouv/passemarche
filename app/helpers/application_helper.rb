# frozen_string_literal: true

module ApplicationHelper
  def current_candidate
    User.find_by(id: session[:user_id]) if respond_to?(:session, true)
  end

  def format_paris_time(datetime, format = '%d/%m/%Y à %H:%M')
    return '-' if datetime.nil?

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
    'services' => { icon: 'icon-services.svg', icon_only: 'icon-services-only.svg', bg: '#FEE7FC' },
    'supplies' => { icon: 'icon-fournitures.svg', icon_only: 'icon-fournitures-only.svg', bg: '#D9EAF8' }
  }.freeze

  def market_type_icon_tag(market_type_codes)
    code = market_type_codes.first
    config = MARKET_TYPE_CONFIGS[code]
    return unless config

    image_tag config[:icon], alt: '', aria: { hidden: true }, width: 36, height: 36, class: 'market-type-icon'
  end

  def commun_scope_icon_svg
    tag.img(src: svg_asset_data_uri('icon-commun-only.svg'), alt: '', aria: { hidden: true }, width: 12, height: 12)
  end

  def market_type_badge_tag(code, label, background: nil)
    config = MARKET_TYPE_CONFIGS[code]
    bg = background || config&.dig(:bg)
    style = bg ? "background-color:#{bg};" : nil
    if config
      icon = tag.img(
        src: svg_asset_data_uri(config[:icon_only]),
        alt: '', aria: { hidden: true }, width: 16, height: 16
      )
      content_tag(:span, icon + label, class: 'fr-tag fr-tag--sm market-type-badge', style:)
    else
      content_tag(:span, label, class: 'fr-tag fr-tag--sm market-type-badge', style:)
    end
  end

  def collapsible_toggle_button(align: :center)
    button = tag.button(
      type: 'button',
      hidden: true,
      class: 'collapsible-list__toggle',
      data: { collapsible_list_target: 'toggle', action: 'collapsible-list#toggle' }
    )
    wrapper_class = align == :left ? 'collapsible-list__toggle-wrapper collapsible-list__toggle-wrapper--left' : 'collapsible-list__toggle-wrapper'
    content_tag(:div, button, class: wrapper_class)
  end

  private

  def svg_asset_data_uri(filename)
    raise ArgumentError, "expected an SVG asset, got #{filename}" unless filename.end_with?('.svg')

    "data:image/svg+xml;base64,#{svg_asset_base64(filename)}"
  end

  def svg_asset_base64(filename)
    Rails.cache.fetch("svg_asset_base64/#{filename}") do
      path = Rails.root.join('app/assets/images', filename)
      Base64.strict_encode64(File.read(path))
    end
  end
end
