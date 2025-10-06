# frozen_string_literal: true

@capacites_techniques_professionnelles
Feature: Capacités techniques et professionnelles - Présentation Intervenants
  En tant que candidat à un marché public
  Je veux pouvoir renseigner l'équipe qui participera au contrat
  Afin de démontrer mes capacités techniques et professionnelles

  Background:
    Given a public market with presentation_intervenants field exists
    And a candidate starts an application for this technical capacities market

  Scenario: Display of empty form with add person functionality
    When I visit the technical capacities step
    Then I should see the title "Présentation de l'équipe qui participera au contrat"
    And I should see the description "Téléchargez la liste des intervenants qui participeront au projet. Si vous ne disposez pas de cette liste, décrivez manuellement l'équipe mobilisée pour le marché : rôles, compétences et expériences. Vous pouvez également joindre les CV des intervenants afin de mettre en valeur leurs qualifications."
    And I should see the "Ajouter un intervenant manuellement" button
    And I should see "Téléchargez une liste des intervenants" section

  Scenario: Form has dynamic person adding infrastructure
    When I visit the technical capacities step
    Then the page should have a nested-form controller for dynamic fields
    And the page should have a button to add persons dynamically

  Scenario: Successful form submission with single person
    Given I have submitted single person data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
    Then the person data should be saved correctly

  Scenario: Successful form submission with multiple persons
    Given I have submitted team data with multiple persons:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
      | Martin     | Marie Claire| Architecte logiciel, PhD             |
    Then both persons data should be saved correctly

  Scenario: Removing a person from the form
    Given I have submitted single person data:
      | nom        | prenoms     | titres                               |
      | Martin     | Marie Claire| Architecte logiciel, PhD             |
    Then only person 2 data should be saved

  Scenario: Form accepts partial person data
    Given I have submitted single person data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre |                                      |
    Then the person data with partial information should be saved

  Scenario: File upload infrastructure for general documents
    When I visit the technical capacities step
    Then I should see file upload infrastructure for documents

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

  Scenario: STI class verification for presentation_intervenants
    When I visit the technical capacities step
    Then the form should have a hidden type field with value "PresentationIntervenants"

  Scenario: Data persistence across navigation
    Given I have submitted person data:
      | nom        | prenoms     | titres                               |
      | Dupont     | Jean Pierre | Ingénieur informatique, Master      |
    When I navigate back to the technical capacities step
    Then the saved person data should be displayed in the form

  Scenario: Maximum person limit (50 persons)
    When I visit the technical capacities step
    Then the form should support adding up to 50 persons

  Scenario: Empty state handling in summary
    When I visit the technical capacities step
    And I click "Suivant" without adding any persons
    And I visit the summary step
    Then I should see "Aucune personne renseignée" in the summary