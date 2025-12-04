class AlertIconComponent < ViewComponent::Base
  def initialize(context: :web)
    @context = context
  end

  def svg_icon(width: 12, height: 12)
    svg = Rails.root.join('app/assets/images/icon-alert-error.svg').read
    svg.gsub!(/\b(width|height)="[^"]*"/, '')
    svg.sub!('<svg', "<svg class='fr-alert__icon' width='#{width}' height='#{height}'")
    svg
  end
end
