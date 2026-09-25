# frozen_string_literal: true

class Grouping::SectionTitleWithEditComponent < ViewComponent::Base
  def initialize(title:, edit_path:, edit_title:)
    @title = title
    @edit_path = edit_path
    @edit_title = edit_title
  end

  private

  attr_reader :title, :edit_path, :edit_title
end
