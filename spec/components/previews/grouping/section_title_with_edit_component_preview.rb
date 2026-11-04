# frozen_string_literal: true

# @label Section Title With Edit Component
# @logical_path grouping
class Grouping::SectionTitleWithEditComponentPreview < Lookbook::Preview
  # @label Default
  def default
    render(Grouping::SectionTitleWithEditComponent.new(
      title: 'Membres du groupement',
      edit_path: '#',
      edit_title: 'Modifier'
    ))
  end
end
