# frozen_string_literal: true

@admin_socle_de_base_reorder
Feature: Admin Socle de Base - Réorganisation des champs par drag & drop
  En tant qu'administrateur Passe Marché
  Je veux réorganiser les champs du socle de base par glisser-déposer
  Afin de définir l'ordre d'affichage des champs

  Background:
    Given I am logged in as an admin user
    And the following market types exist:
      | code     |
      | works    |
      | supplies |
      | services |
    And the following ordered market attributes exist:
      | key      | category_key        | subcategory_key                    | position |
      | champ_a  | identite_entreprise | identite_entreprise_identification | 0        |
      | champ_b  | identite_entreprise | identite_entreprise_contact        | 1        |
      | champ_c  | motifs_exclusion    | motifs_exclusion_fiscales          | 2        |

  Scenario: Page displays drag-reorder Stimulus controller on the table
    When I visit the socle de base page
    Then the attributes table body should have the drag-reorder controller
    And each table row should have a drag handle

  Scenario: Reordering fields updates positions in the database
    When I reorder the socle de base fields as "champ_c, champ_a, champ_b"
    Then the market attribute "champ_c" should have position 0
    And the market attribute "champ_a" should have position 1
    And the market attribute "champ_b" should have position 2

  Scenario: Reorder preserves field data
    When I reorder the socle de base fields as "champ_c, champ_b, champ_a"
    Then the market attribute "champ_c" should still belong to category "motifs_exclusion"
    And the market attribute "champ_a" should still belong to category "identite_entreprise"

  Scenario: Page renders fields in position order
    Given the market attribute "champ_c" has position 0
    And the market attribute "champ_a" has position 1
    And the market attribute "champ_b" has position 2
    When I visit the socle de base page
    Then the first attribute row should be "champ_c"
    And the second attribute row should be "champ_a"
    And the third attribute row should be "champ_b"
