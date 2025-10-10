# frozen_string_literal: true

@capacites_techniques_professionnelles_realisations
Feature: Capacités techniques et professionnelles - Réalisations des dernières années (3 ou 5 ans)
  En tant que candidat à un marché public
  Je veux pouvoir renseigner les principaux travaux effectués au cours des dernières années (3 ou 5 ans)
  Afin de démontrer mes capacités techniques et professionnelles

  Background:
    Given a public market with realisations_livraisons field exists
    And a candidate starts an application for this realisations market

  Scenario: Display of empty form with add realisation functionality
    When I visit the realisations step
    Then I should see the title "Les principaux travaux effectués par votre entreprise au cours des dernières années (3 ou 5 ans)"
    And I should see the realisations "Ajouter une réalisation" button

  Scenario: Form has dynamic realisation adding infrastructure
    When I visit the realisations step
    Then the realisations page should have a nested-form controller for dynamic fields
    And the realisations page should have a button to add realisations dynamically

  Scenario: Successful form submission with single realisation
    Given I have submitted single realisation data:
      | resume                        | date_debut | date_fin   | montant | description                                        |
      | Construction bâtiment municipal | 2023-01-01 | 2023-12-31 | 500000  | Construction complète incluant gros œuvre et finitions |
    Then the realisation data should be saved correctly

  Scenario: Successful form submission with multiple realisations
    Given I have submitted realisations data with multiple items:
      | resume                        | date_debut | date_fin   | montant | description                     |
      | Construction bâtiment municipal | 2023-01-01 | 2023-12-31 | 500000  | Construction complète du bâtiment |
      | Rénovation école primaire       | 2022-06-01 | 2022-12-31 | 350000  | Rénovation totale de l'école     |
    Then both realisations data should be saved correctly

  Scenario: Removing a realisation from the form
    Given I have submitted single realisation data:
      | resume                  | date_debut | date_fin   | montant | description            |
      | Rénovation école        | 2022-06-01 | 2022-12-31 | 350000  | Rénovation complète    |
    Then only realisation 2 data should be saved

  Scenario: Date validation - date_fin must be after date_debut
    When I visit the realisations step
    And I submit invalid date range realisation:
      | resume        | date_debut | date_fin   | montant | description        |
      | Projet invalide | 2023-12-31 | 2023-01-01 | 100000  | Description test   |
    Then I should see validation error "date_fin must be after or equal to date_debut"

  Scenario: Montant validation - must be positive
    When I visit the realisations step
    And I submit invalid montant realisation:
      | resume     | date_debut | date_fin   | montant | description        |
      | Test négatif | 2023-01-01 | 2023-12-31 | -10000  | Description test   |
    Then I should see validation error "montant must be a positive integer"

  Scenario: Display of submitted data in summary
    Given I have submitted realisations data with multiple items:
      | resume                        | date_debut | date_fin   | montant | description                     |
      | Construction bâtiment municipal | 2023-01-01 | 2023-12-31 | 500000  | Construction complète du bâtiment |
      | Rénovation école primaire       | 2022-06-01 | 2022-12-31 | 350000  | Rénovation totale de l'école     |
    When I visit the summary step
    Then I should see the realisations data displayed:
      | realisation     | resume                        | montant   |
      | Réalisation 1   | Construction bâtiment municipal | 500 000 € |
      | Réalisation 2   | Rénovation école primaire       | 350 000 € |

  Scenario: STI class verification
    When I visit the realisations step
    Then the form should have a hidden type field with value "RealisationsLivraisons"

  Scenario: Data persistence across navigation
    Given I have submitted realisation data:
      | resume                  | date_debut | date_fin   | montant | description        |
      | Construction bâtiment   | 2023-01-01 | 2023-12-31 | 500000  | Description complète |
    When I navigate back to the realisations step
    Then the saved realisation data should be displayed in the form

  Scenario: Empty state handling in summary
    When I visit the realisations step
    And I click "Suivant" without adding any realisations
    And I visit the summary step
    Then I should see "Aucune réalisation renseignée" in the realisations summary

  Scenario: File upload for attestation
    Given I have a realisation with attestation:
      | resume        | date_debut | date_fin   | montant | description  | attestation |
      | Projet test   | 2023-01-01 | 2023-12-31 | 100000  | Description  | test.pdf    |
    Then the attestation should be attached to the realisation
    When I visit the summary step
    Then I should see the attestation in the summary
