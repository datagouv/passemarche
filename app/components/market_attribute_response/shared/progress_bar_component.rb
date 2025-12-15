# frozen_string_literal: true

class MarketAttributeResponse::Shared::ProgressBarComponent < ViewComponent::Base
  attr_reader :progress, :hidden

  def initialize(progress: 0, hidden: true)
    @progress = progress
    @hidden = hidden
  end

  def container_css_class
    css = 'fr-mt-1w'
    css += ' hidden' if hidden
    css
  end

  def progress_bar_style
    "width: #{progress}%"
  end
end
