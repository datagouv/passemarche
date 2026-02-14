# frozen_string_literal: true

@admin_archive_market_attribute
Feature: Admin Socle de Base - Archiver un champ
  En tant qu'administrateur Passe Marché
  Je veux archiver un champ du socle de base
  Afin de le retirer de l'usage courant sans le supprimer définitivement

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

  Scenario: ARC-1 - Admin archives a field from the socle de base
    When I visit the socle de base page
    Then I should see 2 rows in the attributes table
    And I should see an archive button for "identite_email"
    When I archive the field "identite_email"
    Then I should see a success flash message containing "identite_email"
    And I should see 1 rows in the attributes table
    And I should not see a row for "identite_email"

  Scenario: ARC-2 - Archived field data is preserved in database
    When I archive the field "identite_email"
    Then the field "identite_email" should still exist in the database
    And the field "identite_email" should have a deleted_at timestamp

  Scenario: ARC-3 - Unauthenticated user cannot archive
    Given I am not logged in
    When I attempt to archive the field "identite_email" without authentication
    Then I should be redirected to the login page
