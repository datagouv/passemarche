# frozen_string_literal: true

# @label Progress Bar
# @logical_path market_attribute_response/shared
class ProgressBarComponentPreview < ViewComponent::Preview
  # @label 0% Progress (Hidden)
  # @display bg_color "#f6f6f6"
  def zero_progress_hidden
    render MarketAttributeResponse::Shared::ProgressBarComponent.new(progress: 0, hidden: true)
  end

  # @label 0% Progress (Visible)
  # @display bg_color "#f6f6f6"
  def zero_progress_visible
    render MarketAttributeResponse::Shared::ProgressBarComponent.new(progress: 0, hidden: false)
  end

  # @label 25% Progress
  # @display bg_color "#f6f6f6"
  def quarter_progress
    render MarketAttributeResponse::Shared::ProgressBarComponent.new(progress: 25, hidden: false)
  end

  # @label 50% Progress
  # @display bg_color "#f6f6f6"
  def half_progress
    render MarketAttributeResponse::Shared::ProgressBarComponent.new(progress: 50, hidden: false)
  end

  # @label 75% Progress
  # @display bg_color "#f6f6f6"
  def three_quarter_progress
    render MarketAttributeResponse::Shared::ProgressBarComponent.new(progress: 75, hidden: false)
  end

  # @label 100% Complete
  # @display bg_color "#f6f6f6"
  def complete
    render MarketAttributeResponse::Shared::ProgressBarComponent.new(progress: 100, hidden: false)
  end
end
