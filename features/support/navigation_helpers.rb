# frozen_string_literal: true

module NavigationHelpers
  # Clique sur le bouton de soumission d'une étape wizard.
  # Préfère "Suivant", tombe sur "Continuer" si "Suivant" n'est pas dispo.
  def submit_step
    if page.has_button?('Suivant', disabled: false)
      click_button 'Suivant'
    elsif page.has_button?('Continuer', disabled: false)
      click_button 'Continuer'
    else
      raise "Aucun bouton de soumission trouvé (cherché : 'Suivant', 'Continuer')"
    end
  end

  # Clique sur un lien ou bouton par son texte.
  def click_on_text(text)
    click_link_or_button(text)
  end

  # Navigue jusqu'à la page de synthèse en soumettant toutes les étapes.
  # Remplit les champs visibles à chaque étape si nécessaire.
  def navigate_to_summary(max_steps: 15)
    max_steps.times do
      break if current_path.include?('summary')

      fill_in_visible_fields
      submit_step
    end
  end
end

World(NavigationHelpers)
