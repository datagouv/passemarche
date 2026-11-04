# frozen_string_literal: true

class Shared::ErrorPageComponent < ViewComponent::Base
  renders_one :action

  def initialize(heading:, paragraphs:)
    @heading = heading
    @paragraphs = Array(paragraphs)
  end

  attr_reader :heading, :paragraphs
end
