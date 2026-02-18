# frozen_string_literal: true

@admin_socle_de_base_filters
Feature: Admin Socle de Base - Recherche et filtres
  En tant qu'administrateur Passe Marché
  Je veux pouvoir rechercher et filtrer les champs du socle de base
  Afin de retrouver rapidement un champ spécifique dans le tableau

  Background:
    Given I am logged in as an admin user
    And the following market types exist:
      | code     |
      | works    |
      | supplies |
      | services |
    And the following categories exist:
      | key                 | buyer_label               | candidate_label                                     | position |
      | identite_entreprise | Identité de l'entreprise  | Les informations du marché et de votre entreprise   | 0        |
      | motifs_exclusion    | Les motifs d'exclusion    | Les justificatifs relatifs aux motifs d'exclusion   | 1        |
    And the following subcategories exist:
      | key            | buyer_label                    | candidate_label                  | category_key        | position |
      | identification | Identification de l'entreprise | Informations de votre entreprise | identite_entreprise | 0        |
      | fiscales       | Obligations fiscales           | Justificatifs fiscaux            | motifs_exclusion    | 0        |
    And the following market attributes with subcategories exist:
      | key            | category_key        | subcategory_key | api_name | market_types           |
      | siret          | identite_entreprise | identification  | Insee    | works,supplies,services |
      | email          | identite_entreprise | identification  |          | works                  |
      | liquidation    | motifs_exclusion    | fiscales        |          | supplies               |

  Scenario: CA-1 - Search by keyword filters table results
    When I visit the socle de base page
    And I search for "Identification"
    Then I should see 2 rows in the attributes table
    And I should see a row for "siret"
    And I should see a row for "email"
    And I should not see a row for "liquidation"

  Scenario: CA-2 - Filter by Type de marché
    When I visit the socle de base page
    And I filter by market type "supplies"
    Then I should see 2 rows in the attributes table
    And I should see a row for "siret"
    And I should see a row for "liquidation"
    And I should not see a row for "email"

  Scenario: CA-3 - Filter by Catégorie
    When I visit the socle de base page
    And I filter by category "identite_entreprise"
    Then I should see 2 rows in the attributes table
    And I should see a row for "siret"
    And I should see a row for "email"
    And I should not see a row for "liquidation"

  Scenario: CA-4 - Filter by Source
    When I visit the socle de base page
    And I filter by source "api"
    Then I should see 1 rows in the attributes table
    And I should see a row for "siret"
    And I should not see a row for "email"

  Scenario: CA-5 - Combined filters show intersection
    When I visit the socle de base page
    And I filter by category "identite_entreprise" and source "manual"
    Then I should see 1 rows in the attributes table
    And I should see a row for "email"
    And I should not see a row for "siret"

  Scenario: CA-6 - No results shows empty state
    When I visit the socle de base page
    And I search for "nonexistent_field_xyz"
    Then I should see "Aucun champ ne correspond à votre recherche."
    And I should see "Réinitialiser les filtres"

  Scenario: CA-7 - Reset filters reloads all fields
    When I visit the socle de base page
    And I search for "nonexistent_field_xyz"
    And I click the reset filters link
    Then I should see 3 rows in the attributes table
