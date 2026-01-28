# frozen_string_literal: true

@admin_socle_de_base
Feature: Admin Socle de Base
  En tant qu'administrateur Passe Marche
  Je veux consulter le socle de base des champs de marche
  Afin de visualiser la structure des formulaires pour acheteurs et candidats

  Background:
    Given I am logged in as an admin user
    And the following market attributes exist:
      | key                        | category_key        | subcategory_key                    | mandatory | api_name |
      | identite_siret             | identite_entreprise | identite_entreprise_identification | true      | Insee    |
      | identite_email             | identite_entreprise | identite_entreprise_contact        | false     |          |
      | motifs_liquidation         | motifs_exclusion    | motifs_exclusion_fiscales          | true      |          |

  Scenario: CA-1 - Default tab is "Identité de l'entreprise"
    When I visit the socle de base page
    Then I should see the page title "Socle de base"
    And the tab "Identité de l'entreprise" should be active
    And I should see the attribute "identite_siret"
    And I should not see the attribute "motifs_liquidation"

  Scenario: CA-2 - Manage dropdown button with actions is visible
    When I visit the socle de base page
    Then I should see the manage dropdown button "Gérer le socle de base"
    When I click on the manage dropdown button
    Then I should see the dropdown action "Exporter"
    And I should see the dropdown action "Créer un champ"
    And I should see the dropdown action "Consulter l'historique"

  Scenario: CA-3 - Search and filters are present
    When I visit the socle de base page
    Then I should see a search field
    And I should see a filter for "Type de marché"
    And I should see a filter for "Source"
    And I should see a filter for "Obligatoire"

  Scenario: CA-4/5 - Tab navigation changes active tab
    When I visit the socle de base page
    And I click on the tab "Les motifs d'exclusion"
    Then the tab "Les motifs d'exclusion" should be active
    And the tab "Identité de l'entreprise" should not be active
    And I should see the attribute "motifs_liquidation"
    And I should not see the attribute "identite_siret"

  Scenario: CA-8/9/10 - Buyer and Candidate blocks with info
    When I visit the socle de base page
    Then I should see the buyer section for "identite_siret"
    And I should see the candidate section for "identite_siret"
    And the buyer section should show category information
    And the buyer section should show subcategory information

  Scenario: CA-11/12 - Mandatory and Complementary badges
    When I visit the socle de base page
    Then the attribute "identite_siret" should have badge "Obligatoire"
    And the attribute "identite_email" should have badge "Complémentaire"

  Scenario: CA-13/14 - API and Manual badges
    When I visit the socle de base page
    Then the attribute "identite_siret" should have badge "API Insee"
    And the attribute "identite_email" should have badge "Manuel"

  Scenario: CA-15 - Edit button visible in each accordion
    When I visit the socle de base page
    Then I should see an edit button for "identite_siret"

  Scenario: Stats cards display correct counts
    When I visit the socle de base page
    Then I should see the stat card "Champs total" with value "3"
    And I should see the stat card "Champs API" with value "1"
    And I should see the stat card "Champs manuels" with value "2"
    And I should see the stat card "Champs obligatoires" with value "2"

  Scenario: Filter by source API
    When I visit the socle de base page
    And I filter by source "API"
    Then I should see the attribute "identite_siret"
    And I should not see the attribute "identite_email"

  Scenario: Filter by mandatory
    When I visit the socle de base page
    And I filter by mandatory "Oui"
    Then I should see the attribute "identite_siret"
    And I should not see the attribute "identite_email"
