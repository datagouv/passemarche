# frozen_string_literal: true
@buyer_lot_config
Feature: Buyer Lot Configuration Step
  En tant qu'acheteur public
  Je veux pouvoir configurer les lots de mon marché
  Afin de limiter ou non le nombre de lots auxquels les candidats peuvent répondre

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And I create a public market with multiple lots

  Scenario: L'acheteur accède à la page de configuration des lots
    When I visit the lot_config page for my public market
    Then I should see "Configurer le type de vos lots"
    And I should see "Lot 1"
    And I should see "Lot 2"
    And I should see "Lot 3"
    And I should see "Souhaitez-vous limiter le nombre de lots ?"

  Scenario: La page lot_config apparaît dans le wizard après le setup
    When I visit the setup page for my public market
    And I click on "Débuter l'activation de"
    Then I should be on the lot_config page
    And I should see "Configurer le type de vos lots"

  Scenario: L'acheteur choisit de ne pas limiter les lots
    When I visit the lot_config page for my public market
    And I choose "Non" for lot limit
    And I submit the lot_config form
    Then the public market should have no lot limit

  Scenario: L'acheteur choisit de limiter les lots
    When I visit the lot_config page for my public market
    And I choose "Oui" for lot limit
    And I set the lot limit to 2
    And I submit the lot_config form
    Then the public market should have a lot limit of 2

  Scenario: La limite de lots apparaît dans le résumé
    Given the buyer lot config public market has a lot limit of 2
    When I visit the summary page for my public market
    Then I should see "Limite de lots par candidat"
    And I should see "2 lots maximum"

  Scenario: La limite de lots n'apparaît pas dans le résumé si non définie
    When I visit the summary page for my public market
    Then the lot limit section should not be visible

  Scenario: L'acheteur soumet sans renseigner le nombre de lots (Oui + champ vide)
    When I visit the lot_config page for my public market
    And I choose "Oui" for lot limit
    And I submit the lot_config form
    Then I should be on the lot_config page
    And I should see "Veuillez indiquer le nombre maximum de lots."
    And the public market should have no lot limit

  Scenario: Navigation complète du wizard avec lots
    When I visit the setup page for my public market
    And I click on "Débuter l'activation de"
    Then I should be on the lot_config page
    When I choose "Non" for lot limit
    And I submit the lot_config form
    Then I should be on the first category page
