# frozen_string_literal: true

@buyer_modify_configuration
Feature: Modification de la configuration avant publication
  En tant qu'acheteur public
  Je veux pouvoir modifier la configuration de mon marché
  Tant que la consultation n'a pas été publiée

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And a "supplies" market type exists with mandatory fields

  Scenario: CA-1 - L'acheteur accède au wizard sur un marché transmis non publié
    Given a completed but non-published market exists for the current editor
    When I visit the setup page for the completed market
    Then I should see the setup page content

  Scenario: CA-2 - L'acheteur re-soumet la configuration et un nouveau webhook est envoyé
    Given a completed but non-published market exists for the current editor
    When I visit the summary page for the completed market
    And I submit the summary step
    Then the market should have a new completed_at timestamp
    And the market sync status should be reset

  Scenario: CA-3 - Un marché publié bloque l'accès au wizard
    Given a published market exists for the current editor
    When I visit the setup page for the published market
    Then I should be redirected to the published page
    And I should see the published market message

  @javascript
  Scenario: CA-4 - Sur un marché déjà transmis sans champs optionnels sélectionnés, "Non" reste pré-sélectionné
    Given a completed but non-published market exists for the current editor
    And this market has an optional field in the "identite_entreprise" category
    When I visit the category page with optional fields for the completed market
    Then the "Non" option should be selected
    And I should see a button "Suivant"
