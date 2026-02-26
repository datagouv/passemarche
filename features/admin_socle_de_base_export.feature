# frozen_string_literal: true

@admin_socle_de_base_export
Feature: Admin Socle de Base - Export CSV
  En tant qu'administrateur Passe Marché
  Je veux exporter les champs du socle de base en CSV
  Afin de pouvoir les analyser ou les partager

  Background:
    Given I am logged in as an admin user
    And the following market types exist:
      | code     |
      | works    |
      | supplies |
      | services |
    And the following market attributes exist:
      | key                | category_key        | subcategory_key                    | mandatory | api_name | market_types            |
      | identite_siret     | identite_entreprise | identite_entreprise_identification | true      | Insee    | works,supplies,services |
      | identite_email     | identite_entreprise | identite_entreprise_contact        | false     |          | works                   |
      | motifs_liquidation | motifs_exclusion    | motifs_exclusion_fiscales          | true      |          |                         |

  Scenario: EX-1 - Admin exports the socle de base as CSV
    When I visit the socle de base page
    And I click the export link in the manage dropdown
    Then I should receive a CSV file with the correct filename
    And the CSV should contain the correct headers
    And the CSV should contain 3 data rows

  Scenario: EX-2 - Export respects category filter
    When I export the socle de base with category filter "identite_entreprise"
    Then the CSV should contain 2 data rows
    And the CSV should contain a row with key "identite_siret"
    And the CSV should contain a row with key "identite_email"
    And the CSV should not contain a row with key "motifs_liquidation"

  Scenario: EX-3 - Unauthenticated user cannot export
    Given I am not logged in
    When I request the socle de base export
    Then I should be redirected to the login page
