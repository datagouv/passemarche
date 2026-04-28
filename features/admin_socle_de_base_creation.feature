# frozen_string_literal: true

@admin_socle_de_base_creation
Feature: Admin Socle de Base - Créer un nouveau champ
  En tant qu'administrateur Passe Marché
  Je veux créer un nouveau champ dans le socle de base
  Afin d'enrichir le formulaire de candidature

  Background:
    Given I am logged in as an admin user
    And the following categories with labels exist:
      | key                 | buyer_label              | candidate_label          |
      | identite_entreprise | Identité de l'entreprise | Identité de l'entreprise |
    And the following subcategories with labels exist:
      | key            | category_key        | buyer_label    | candidate_label |
      | identification | identite_entreprise | Identification | Identification  |
    And the following market types exist:
      | code     |
      | works    |
      | services |

  Scenario: Access the creation form from the index
    When I visit the socle de base page
    And I click on "Créer un champ"
    Then I should see the page title "Créer un nouveau champ"
    And I should see the form block "Informations générales"
    And I should see the form block "Description"
    And I should see the form block "Configuration"

  Scenario: Create a manual field with all valid fields
    When I visit the new market attribute page
    And I fill in the creation form with valid manual params
    And I submit the creation form
    Then I should be redirected to the socle de base index
    And I should see a success message "créé avec succès"

  Scenario: Create an API field with api_name and api_key
    Given an existing API market attribute with api_name "Insee" and api_key "siret"
    When I visit the new market attribute page
    And I fill in the creation form with valid API params
    And I submit the creation form
    Then I should be redirected to the socle de base index
    And I should see a success message "créé avec succès"

  Scenario: Validation error when buyer_name is missing
    When I visit the new market attribute page
    And I fill in the creation form without buyer_name
    And I submit the creation form
    Then I should see an error in the form

  Scenario: Validation error when no market type is selected
    When I visit the new market attribute page
    And I fill in the creation form without market types
    And I submit the creation form
    Then I should see an error in the form

  Scenario: Cancel returns to the index without creating
    Given I note the current market attribute count
    When I visit the new market attribute page
    And I click on "Annuler"
    Then I should be redirected to the socle de base index
    And the market attribute count should not have changed

  Scenario: Unauthenticated user cannot access the creation form
    Given I am not logged in
    When I visit the new market attribute page
    Then I should be redirected to the login page
