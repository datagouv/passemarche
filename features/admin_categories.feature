# frozen_string_literal: true

@admin_categories
Feature: Admin - Catégories et sous-catégories
  En tant qu'administrateur Passe Marché
  Je veux gérer les catégories et sous-catégories du socle de base
  Afin de visualiser et modifier les libellés acheteur et candidat

  Background:
    Given I am logged in as an admin user
    And the following categories exist:
      | key                 | buyer_label               | candidate_label                                     | position |
      | identite_entreprise | Identité de l'entreprise  | Les informations du marché et de votre entreprise   | 0        |
      | motifs_exclusion    | Les motifs d'exclusion    | Les justificatifs relatifs aux motifs d'exclusion   | 1        |
    And the following subcategories exist:
      | key                      | buyer_label                       | candidate_label                   | category_key        | position |
      | identification           | Identification de l'entreprise    | Informations de votre entreprise  | identite_entreprise | 0        |
      | bilans                   | Bilans                            | Bilans                            | identite_entreprise | 1        |

  Scenario: Page displays two distinct tables for categories and subcategories
    When I visit the categories page
    Then I should see the page title "Catégories et sous catégories"
    And I should see a categories table with headers "Catégorie Acheteur", "Catégorie Candidat", "Actions"
    And I should see a subcategories table with headers "Sous catégorie acheteur", "Sous Catégorie candidat", "Actions"

  Scenario: Categories table displays buyer and candidate labels
    When I visit the categories page
    Then the categories table should display "Identité de l'entreprise" and "Les informations du marché et de votre entreprise"
    And the categories table should display "Les motifs d'exclusion" and "Les justificatifs relatifs aux motifs d'exclusion"

  Scenario: Subcategories table displays buyer and candidate labels
    When I visit the categories page
    Then the subcategories table should display "Identification de l'entreprise" and "Informations de votre entreprise"
    And the subcategories table should display "Bilans" and "Bilans"

  Scenario: Each row has an edit button
    When I visit the categories page
    Then each category row should have a "Modifier" button
    And each subcategory row should have a "Modifier" button

  Scenario: Create dropdown shows two options
    When I visit the categories page
    Then I should see the "Créer" dropdown button
    And the create dropdown should contain "Créer une nouvelle catégorie"
    And the create dropdown should contain "Créer une nouvelle sous-catégorie"

  Scenario: Each table has drag handles
    When I visit the categories page
    Then each category row should have a drag handle
    And each subcategory row should have a drag handle

  Scenario: Reorder categories updates positions
    When I reorder categories as "motifs_exclusion, identite_entreprise"
    Then the category "motifs_exclusion" should have position 0
    And the category "identite_entreprise" should have position 1

  Scenario: Reorder subcategories updates positions independently
    When I reorder subcategories as "bilans, identification"
    Then the subcategory "bilans" should have position 0
    And the subcategory "identification" should have position 1
    And the category "identite_entreprise" should still have position 0

  Scenario: Page is accessible from Socle de Base manage dropdown
    When I visit the socle de base page
    Then the manage dropdown should contain a link to the categories page

  Scenario: Back link returns to Socle de Base
    When I visit the categories page
    Then I should see a back link to the Socle de Base page

  Scenario: Soft-deleted categories are not displayed
    Given a soft-deleted category "deleted_cat" exists
    When I visit the categories page
    Then I should not see "deleted_cat" in the categories table

  Scenario: Soft-deleted subcategories are not displayed
    Given a soft-deleted subcategory "deleted_sub" exists
    When I visit the categories page
    Then I should not see "deleted_sub" in the subcategories table
