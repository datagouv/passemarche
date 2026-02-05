# frozen_string_literal: true

@admin_socle_de_base
Feature: Admin Socle de Base - Accordéon multi-niveaux
  En tant qu'administrateur Passe Marché
  Je veux consulter les catégories, sous-catégories et champs du socle de base
  sous forme d'accordéon multi-niveaux, avec les libellés Acheteur et Candidat
  Afin de visualiser la configuration complète du formulaire et ses traductions

  Background:
    Given I am logged in as an admin user
    And the following market attributes exist:
      | key                        | category_key        | subcategory_key                    | mandatory | api_name |
      | identite_siret             | identite_entreprise | identite_entreprise_identification | true      | Insee    |
      | identite_email             | identite_entreprise | identite_entreprise_contact        | false     |          |
      | motifs_liquidation         | motifs_exclusion    | motifs_exclusion_fiscales          | true      |          |

  Scenario: CA-1 - Admin sees 4 categories as accordion panels
    When I visit the socle de base page
    Then I should see the page title "Socle de base"
    And I should see a category accordion for "identite_entreprise"
    And I should see a category accordion for "motifs_exclusion"

  Scenario: CA-2 - Category accordion contains buyer/candidate labels and subcategory accordions
    When I visit the socle de base page
    Then the category "identite_entreprise" should contain buyer and candidate labels
    And the category "identite_entreprise" should contain a "Modifier" link
    And the category "identite_entreprise" should contain a subcategory accordion for "identite_entreprise_identification"
    And the category "identite_entreprise" should contain a subcategory accordion for "identite_entreprise_contact"

  Scenario: CA-3 - Subcategory accordion contains buyer/candidate labels and field accordions
    When I visit the socle de base page
    Then the subcategory "identite_entreprise_identification" should contain buyer and candidate labels
    And the subcategory "identite_entreprise_identification" should contain a "Modifier" link
    And the subcategory "identite_entreprise_identification" should contain a field accordion for "identite_siret"

  Scenario: CA-4 - Field accordion contains buyer and candidate labels
    When I visit the socle de base page
    Then the field "identite_siret" should contain buyer and candidate labels
    And the field "identite_siret" should contain a "Modifier" link

  Scenario: CA-5 - Edit buttons are placeholder links
    When I visit the socle de base page
    Then all "Modifier" links should point to "#"

  Scenario: CA-6 - Soft-deleted attributes are not displayed
    Given a soft-deleted market attribute "deleted_attr" exists in "identite_entreprise"
    When I visit the socle de base page
    Then I should not see a field accordion for "deleted_attr"

  Scenario: CA-7 - Acheteur categories page no longer exists
    When I visit the acheteur categories page
    Then I should get a routing error

  Scenario: Stats cards display correct counts
    When I visit the socle de base page
    Then I should see the stat card "Champs total" with value "3"
    And I should see the stat card "Champs API" with value "1"
    And I should see the stat card "Champs manuels" with value "2"
    And I should see the stat card "Champs obligatoires" with value "2"

  Scenario: Manage dropdown button with actions is visible
    When I visit the socle de base page
    Then I should see the manage dropdown button "Gérer le socle de base"
