# frozen_string_literal: true

@admin_socle_de_base
Feature: Admin Socle de Base - Tableau des champs
  En tant qu'administrateur Passe Marché
  Je veux consulter les champs du socle de base sous forme de tableau
  Afin de visualiser la configuration complète et la répartition entre champs API et manuels

  Background:
    Given I am logged in as an admin user
    And the following market types exist:
      | code     |
      | works    |
      | supplies |
      | services |
    And the following market attributes exist:
      | key                | category_key        | subcategory_key                    | mandatory | api_name | market_types     |
      | identite_siret     | identite_entreprise | identite_entreprise_identification | true      | Insee    | works,supplies,services |
      | identite_email     | identite_entreprise | identite_entreprise_contact        | false     |          | works            |
      | motifs_liquidation | motifs_exclusion    | motifs_exclusion_fiscales          | true      |          |                  |

  Scenario: CA-1 - Table displays all fields with correct columns
    When I visit the socle de base page
    Then I should see the page title "Socle de base"
    And I should see a table with headers "Catégorie", "Sous Catégorie", "Champ", "Type de marché", "Source", "Actions"
    And I should see 3 rows in the attributes table

  Scenario: CA-2 - Market type badges display correctly
    When I visit the socle de base page
    Then the row for "identite_siret" should have all market type badges active
    And the row for "identite_email" should have only "T" badge active
    And the row for "motifs_liquidation" should have no market type badges active

  Scenario: CA-3 - Source column displays API or manual
    When I visit the socle de base page
    Then the row for "identite_siret" should show source "API Insee"
    And the row for "identite_email" should show source "Manuel"

  Scenario: CA-4 - Edit buttons are placeholder links
    When I visit the socle de base page
    Then all "Modifier" links should point to "#"

  Scenario: CA-5 - Soft-deleted attributes are not displayed
    Given a soft-deleted market attribute "deleted_attr" exists in "identite_entreprise"
    When I visit the socle de base page
    Then I should not see a row for "deleted_attr"

  Scenario: CA-6 - Drag handle icons are visible
    When I visit the socle de base page
    Then each table row should have a drag handle icon

  Scenario: Stats cards display correct counts
    When I visit the socle de base page
    Then I should see the stat card "Champs total" with value "3"
    And I should see the stat card "Champs API" with value "1"
    And I should see the stat card "Champs manuels" with value "2"
    And I should see the stat card "Champs obligatoires" with value "2"

  Scenario: Manage dropdown button with actions is visible
    When I visit the socle de base page
    Then I should see the manage dropdown button "Gérer le socle de base"
