# frozen_string_literal: true
@buyer_flow
Feature: Buyer Configuration Flow
  En tant qu'acheteur public
  Je veux pouvoir configurer mon marché étape par étape
  Afin de paramétrer les documents requis pour les candidatures

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And I create a public market with the following details:
      | name | Fourniture de matériel informatique |
      | lot_name    | Lot 1 - Ordinateurs portables       |
      | deadline    | 2025-12-31T23:59:59Z                |
      | siret        | 13002526500013                      |
      | market_types | supplies                            |

  Scenario: Navigation complète du flux acheteur - aller simple
    When I visit the setup page for my public market
    Then I should see "Bienvenue,"
    And I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "Cochez cette case uniquement si votre marché concerne la défense ou la sécurité"

    When I click on "Débuter l'activation de"
    Then I should be on the first category page
    And I should see "Étape 1 sur"
    And I should see a "Précédent" button
    And I should see a button "Suivant"

    When I navigate through all category steps to summary
    Then I should be on the summary page
    And I should see "Synthèse des paramètres de la candidature"
    And I should see "Informations du marché"
    And I should see a button "Finaliser la configuration"

  Scenario: Navigation arrière avec les boutons Précédent
    Given I am on the summary page for my public market
    When I click on "Précédent"
    Then I should be on a category page
    And I should see a "Précédent" button

  Scenario: Vérification de la cohérence des informations du marché à travers les étapes
    When I visit the setup page for my public market
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "Fournitures"

    When I click on "Débuter l'activation de"
    Then I should be on the first category page

    When I navigate through all category steps to summary
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "Fournitures"

  Scenario: Stepper indique correctement l'étape courante
    When I visit the first category page for my public market
    Then I should see a stepper
    And the stepper should indicate the first category step as current

  Scenario: Navigation directe vers différentes étapes
    When I visit the setup page for my public market
    Then I should be on the setup page

    When I visit the first category page for my public market
    Then I should be on the first category page

    When I visit the summary page for my public market
    Then I should be on the summary page
    And I should see "Synthèse des paramètres de la candidature"

  Scenario: Marquer un marché comme défense en cochant la case
    Given I visit the setup page for my public market
    When I check the "defense_industry" checkbox
    And I click on "Débuter l'activation de"
    Then the public market should be marked as defense_industry
    And I should be on the first category page

  Scenario: Ne pas marquer un marché comme défense en laissant la case décochée
    Given I visit the setup page for my public market
    When I click on "Débuter l'activation de"
    Then the public market should not be marked as defense_industry
    And I should be on the first category page

  Scenario: Marché avec défense pré-configuré par l'éditeur
    When I create a defense_industry public market with the following details:
      | name | Fourniture de matériel militaire |
      | deadline    | 2025-12-31T23:59:59Z            |
      | siret        | 13002526500013                  |
      | market_types | supplies                        |
      | defense_industry     | true                            |
    And I visit the setup page for my public market
    Then the defense_industry checkbox should be disabled and checked
    And I should see "Cette désignation a été définie par"

  Scenario: Sélection de documents supplémentaires avec question oui/non
    When I visit a category page with optional fields for my public market
    Then I should see "Souhaitez-vous demander des informations complémentaires aux candidats"
    And I should see "Oui"
    And I should see "Non"

  Scenario: Les attributs obligatoires sont automatiquement ajoutés après setup
    When I visit the setup page for my public market
    And I click on "Débuter l'activation de"
    Then the public market should have all required attributes from its market types
    And I should be on the first category page
