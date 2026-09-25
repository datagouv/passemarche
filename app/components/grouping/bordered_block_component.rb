# frozen_string_literal: true

class Grouping::BorderedBlockComponent < ViewComponent::Base
  def initialize(icon_class:, title:)
    @icon_class = icon_class
    @title = title
  end

  private

  attr_reader :icon_class, :title
end
