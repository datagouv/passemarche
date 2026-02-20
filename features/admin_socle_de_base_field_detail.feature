# frozen_string_literal: true

@admin_socle_de_base_field_detail
Feature: Admin Socle de Base - Consultation et edition d'un champ
  En tant qu'administrateur Passe Marche
  Je veux consulter et modifier les champs du socle de base
  Afin de gerer la configuration de chaque champ

  Background:
    Given I am logged in as an admin user
    And the following market types exist:
      | code     |
      | works    |
      | supplies |
      | services |
    And the following market attributes exist:
      | key            | category_key        | subcategory_key                    | mandatory | api_name | market_types            |
      | identite_siret | identite_entreprise | identite_entreprise_identification | true      | Insee    | works,supplies,services |

  Scenario: View field detail page from table
    When I visit the socle de base page
    And I click the "Modifier" link for "identite_siret"
    Then I should see the field detail page for "identite_siret"
    And I should see the configuration section showing "API"

  Scenario: Back link returns to field list
    When I visit the field detail page for "identite_siret"
    And I click the back link
    Then I should be on the socle de base page

  Scenario: General info section displays field type and mandatory status
    When I visit the field detail page for "identite_siret"
    Then I should see the general info section
    And I should see the mandatory badge

  Scenario: Description section shows buyer and candidate views
    When I visit the field detail page for "identite_siret"
    Then I should see the buyer view section
    And I should see the candidate view section

  Scenario: Edit page displays form with current values
    When I visit the edit page for "identite_siret"
    Then I should see the edit form title "Modifier le champ"
    And I should see the input type select
    And I should see the mandatory checkbox
    And I should see market type checkboxes

  Scenario: Submit valid changes saves and redirects to show
    When I visit the edit page for "identite_siret"
    And I toggle the mandatory checkbox
    And I submit the edit form
    Then I should see a success notice

  Scenario: Cancel returns to show page without changes
    When I visit the edit page for "identite_siret"
    And I click the cancel link
    Then I should see the field detail page for "identite_siret"

  Scenario: Archive button soft-deletes the field
    When I visit the field detail page for "identite_siret"
    And I click the archive button
    Then I should be on the socle de base page
    And the field "identite_siret" should be archived
