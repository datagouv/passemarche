# frozen_string_literal: true

# @label Error Page Component
# @logical_path shared
class Shared::ErrorPageComponentPreview < Lookbook::Preview
  # @label Sans action
  def default
    render(Shared::ErrorPageComponent.new(
      heading: "La candidature recherchée n'a pas été trouvée",
      paragraphs: "Le lien que vous avez utilisé est incorrect ou cette candidature n'existe plus."
    ))
  end

  # @label Avec action
  def with_action
    render(Shared::ErrorPageComponent.new(
      heading: 'Vous ne pouvez plus modifier votre candidature',
      paragraphs: [
        'La date limite de réception des candidatures est dépassée.',
        'Pour toutes questions, contactez la plateforme de marché.'
      ]
    )) do |component|
      component.with_action { '<a class="fr-btn" href="#">Revenir sur la plateforme de marché</a>'.html_safe }
    end
  end
end
