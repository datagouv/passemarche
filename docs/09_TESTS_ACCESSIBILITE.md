# Tests d'accessibilité

Ce document explique comment exécuter et créer des tests d'accessibilité pour Passe Marché.

## Outils utilisés

- **axe-core** : Moteur de test d'accessibilité basé sur les standards WCAG
- **axe-core-capybara** : Intégration avec Capybara pour les tests système
- **axe-core-rspec** : Matchers RSpec pour les assertions d'accessibilité

## Exécution des tests

### Tests RSpec

```bash
# Exécuter tous les tests d'accessibilité
bundle exec rspec spec/accessibility/

# Exécuter un fichier spécifique
bundle exec rspec spec/accessibility/public_pages_spec.rb
```

### Tests Cucumber

```bash
# Exécuter les scénarios d'accessibilité
bundle exec cucumber features/accessibility.feature
```

## Structure des tests

### Tests RSpec (`spec/accessibility/`)

- `public_pages_spec.rb` : Pages publiques (accueil, candidat, acheteur)
- `admin_pages_spec.rb` : Pages d'administration

### Tests Cucumber (`features/accessibility.feature`)

Les scénarios Cucumber peuvent utiliser l'étape :

```gherkin
Then the page should be accessible
```

Pour exclure des sélecteurs spécifiques :

```gherkin
Then the page should be accessible excluding ".fr-modal__overlay"
```

## Ajouter de nouveaux tests

### Créer un nouveau test RSpec

```ruby
require 'rails_helper'

RSpec.describe 'My page accessibility', type: :system do
  before do
    driven_by(:headless_chromium)
  end

  it 'meets accessibility standards', :js do
    visit my_path

    check_accessibility
  end
end
```

### Helpers disponibles

```ruby
# Vérification standard avec exclusions DSFR
check_accessibility

# Vérification sans exclusions
check_accessibility(exclusions: [])

# Vérification WCAG 2.1 AA
check_accessibility_wcag21aa
```

## Exclusions DSFR

Certains composants du DSFR peuvent déclencher des faux positifs. Les exclusions par défaut sont configurées dans `spec/support/accessibility_helpers.rb` :

```ruby
DSFR_EXCLUSIONS = [
  '.fr-modal__overlay'
].freeze
```

Pour ajouter une exclusion temporaire :

```ruby
check_accessibility(exclusions: DSFR_EXCLUSIONS + ['.my-custom-selector'])
```

## Prérequis

Les tests d'accessibilité nécessitent un navigateur Chrome/Chromium en mode headless. Assurez-vous que :

- Chromium est installé (`/usr/bin/chromium-browser`)
- ChromeDriver est disponible

## Ressources

- [axe-core Documentation](https://github.com/dequelabs/axe-core)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [DSFR Accessibilité](https://www.systeme-de-design.gouv.fr/fondamentaux/accessibilite)
