# frozen_string_literal: true

# @label Bordered Block Component
# @logical_path grouping
class Grouping::BorderedBlockComponentPreview < Lookbook::Preview
  # @label With members block content
  def default
    render(Grouping::BorderedBlockComponent.new(icon_class: 'fr-icon-team-fill', title: 'Composition du groupement')) do
      '<div class="fr-p-4w">Contenu du bloc</div>'.html_safe
    end
  end
end
