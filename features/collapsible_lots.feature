# frozen_string_literal: true
@collapsible_lots
Feature: Affichage collapsible des lots
  En tant qu'utilisateur (acheteur ou candidat)
  Quand un marché a beaucoup de lots
  Je veux voir les lots tronqués avec un bouton "Voir plus"
  Afin de ne pas être submergé par une longue liste

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And I create a public market with many lots

  Scenario: La page lot_config acheteur a le controller collapsible sur le tableau
    When I visit the lot_config page for my public market
    Then the lots table should have the collapsible-rows controller

  Scenario: La page form_config acheteur a le controller collapsible dans la sidebar
    When I visit the form_config page for my public market
    Then the lots sidebar should have the collapsible-list controller

  Scenario: La page summary acheteur a le controller collapsible sur la liste des lots
    When I visit the summary page for my public market
    Then the lots list should have the collapsible-list controller
