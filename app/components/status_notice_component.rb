class StatusNoticeComponent < ViewComponent::Base
  COLORS = {
    success: { background: 'fr-background-contrast--success', text: 'fr-text-default--success' },
    warning: { background: 'fr-background-contrast--warning', text: 'fr-text-default--warning' }
  }.freeze

  def initialize(title:, color:)
    @title = title
    @color = COLORS.fetch(color.to_sym)
  end

  attr_reader :title, :color
end
