class CheckIconComponent < ViewComponent::Base
  def initialize(context: :web)
    @context = context
  end

  def svg_icon(width: 12, height: 12)
    svg = Rails.root.join('app/assets/images/icon-api-success.svg').read
    svg.gsub!(/\b(width|height)="[^"]*"/, '')
    svg.sub('<svg', "<svg width='#{width}' height='#{height}'")
  end
end
