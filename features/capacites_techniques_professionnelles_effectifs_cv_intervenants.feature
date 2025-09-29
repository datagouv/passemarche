# frozen_string_literal: true

@capacites_techniques_professionnelles
Feature: Capacités techniques et professionnelles - Effectifs CV Intervenants
  En tant que candidat à un marché public
  Je veux pouvoir renseigner l'équipe qui participera au contrat
  Afin de démontrer mes capacités techniques et professionnelles

  Background:
    Given a public market with capacites_techniques_professionnelles_effectifs_cv_intervenants field exists
    And a candidate starts an application for this technical capacities market

  Scenario: Display of empty form with add person functionality
    When I visit the technical capacities step
    Then I should see the title "Présentation de l'équipe qui participera au contrat"
    And I should see the description "Décrivez l'équipe mobilisée pour le marché en renseignant pour chaque personne nom, prénoms, titres d'études et professionnels"
    And I should see the "Ajouter une personne" button
    And I should see "Documents associés" section

  @javascript @wip
  Scenario: Adding multiple persons dynamically
    When I visit the technical capacities step
    And I click "Ajouter une personne"
    Then I should see person form 1 with all required fields
    When I click "Ajouter une personne"
    Then I should see person form 2 with all required fields
    And both person forms should have distinct field names

  @javascript @wip
  Scenario: Successful form submission with single person
    When I visit the technical capacities step
    And I click "Ajouter une personne"
    And I fill in person 1 data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
    And I click "Suivant"
    Then the technical capacity form should be submitted successfully
    And the person data should be saved correctly

  @javascript @wip
  Scenario: Successful form submission with multiple persons
    When I visit the technical capacities step
    And I click "Ajouter une personne"
    And I fill in person 1 data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
    And I click "Ajouter une personne"
    And I fill in person 2 data:
      | nom        | prenoms     | titres                               |
      | Martin     | Marie Claire| Architecte logiciel, PhD             |
    And I click "Suivant"
    Then the technical capacity form should be submitted successfully
    And both persons data should be saved correctly

  @javascript @wip
  Scenario: Removing a person from the form
    When I visit the technical capacities step
    And I click "Ajouter une personne"
    And I fill in person 1 data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
    And I click "Ajouter une personne"
    And I fill in person 2 data:
      | nom        | prenoms     | titres                               |
      | Martin     | Marie Claire| Architecte logiciel, PhD             |
    When I remove person 1
    And I click "Suivant"
    Then the technical capacity form should be submitted successfully
    And only person 2 data should be saved

  @javascript @wip
  Scenario: Validation errors for missing required fields
    When I visit the technical capacities step
    And I click "Ajouter une personne"
    And I fill in partial person data:
      | nom        | prenoms     | titres                               |
      |            | Jean Pierre | Ingénieur informatique              |
    And I click "Suivant"
    Then I should see validation errors for required fields
    And the technical capacity form should not be submitted

  @javascript @wip
  Scenario: File upload for general documents
    When I visit the technical capacities step
    And I click "Ajouter une personne"
    And I fill in person 1 data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
    And I attach a general document "CV_equipe.pdf"
    And I click "Suivant"
    Then the technical capacity form should be submitted successfully
    And the document should be attached to the response

  Scenario: Display of submitted data in summary
    Given I have submitted team data with multiple persons:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
      | Martin     | Marie Claire| Architecte logiciel, PhD             |
    When I visit the summary step
    Then I should see the team data displayed:
      | person     | nom        | prenoms     | titres                               |
      | Personne 1 | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
      | Personne 2 | Martin     | Marie Claire| Architecte logiciel, PhD             |

  @javascript @wip
  Scenario: STI class verification for capacites_techniques_professionnelles_effectifs_cv_intervenants
    When I visit the technical capacities step
    Then the form should have a hidden type field with value "CapacitesTechniquesProfessionnellesEffectifsCvIntervenants"
    When I submit valid team data
    Then the technical capacity response should be created with class "MarketAttributeResponse::CapacitesTechniquesProfessionnellesEffectifsCvIntervenants"
    And the technical capacity response should have the correct JSON structure

  @javascript @wip
  Scenario: Data persistence across navigation
    When I visit the technical capacities step
    And I click "Ajouter une personne"
    And I fill in person 1 data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
    And I click "Suivant"
    And I navigate back to the technical capacities step
    Then the person 1 fields should contain the saved data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |

  @javascript @wip
  Scenario: Maximum person limit (50 persons)
    When I visit the technical capacities step
    And I add 50 persons
    Then the "Ajouter une personne" button should be disabled
    When I try to add another person
    Then no additional person form should appear

  Scenario: Empty state handling in summary
    When I visit the technical capacities step
    And I click "Suivant" without adding any persons
    And I visit the summary step
    Then I should see "Aucune personne renseignée" in the summary