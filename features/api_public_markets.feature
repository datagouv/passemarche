# frozen_string_literal: true

@api_public_markets
Feature: API Public Markets Management
  En tant qu'éditeur de plateforme de marchés publics
  Je veux pouvoir créer des marchés publics via l'API
  Afin de permettre aux acheteurs de configurer leurs consultations

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token

  Scenario: Créer un marché public avec succès
    When I create a public market with the following details:
      | name | Fourniture de matériel informatique |
      | lot_name    | Lot 1 - Ordinateurs portables       |
      | deadline    | 2025-12-31T23:59:59Z                |
      | market_type | supplies                            |
    Then the response status should be 201
    And I should receive a public market identifier starting with "VR-"
    And I should receive a configuration URL
    And the public market should be saved in the database

  Scenario: Créer un marché public avec tous les champs optionnels
    When I create a public market with the following details:
      | name | Services de maintenance            |
      | deadline    | 2025-06-30T18:00:00Z              |
      | market_type | services                          |
    Then the response status should be 201
    And I should receive a public market identifier
    And the public market should have no lot name

  Scenario: Échec de création sans token d'authentification
    Given I do not have an access token
    When I create a public market with the following details:
      | name | Test Market        |
      | deadline    | 2025-12-31T23:59:59Z |
      | market_type | supplies            |
    Then the response status should be 401
    And I should receive an authentication error

  Scenario: Échec de création avec un token invalide
    Given I have an invalid access token
    When I create a public market with the following details:
      | name | Test Market        |
      | deadline    | 2025-12-31T23:59:59Z |
      | market_type | supplies            |
    Then the response status should be 401
    And I should receive an authentication error

  Scenario: Échec de création sans nom de marché
    When I create a public market with the following details:
      | lot_name    | Lot 1              |
      | deadline    | 2025-12-31T23:59:59Z |
      | market_type | supplies            |
    Then the response status should be 422
    And the response should contain validation errors

  Scenario: Échec de création sans deadline
    When I create a public market with the following details:
      | name | Test Market |
      | market_type | supplies    |
    Then the response status should be 422
    And the response should contain validation errors

  Scenario: Échec de création sans type de marché
    When I create a public market with the following details:
      | name | Test Market        |
      | deadline    | 2025-12-31T23:59:59Z |
    Then the response status should be 422
    And the response should contain validation errors

  Scenario: Créer plusieurs marchés publics pour le même éditeur
    When I create a public market with the following details:
      | name | Premier marché     |
      | deadline    | 2025-12-31T23:59:59Z |
      | market_type | supplies            |
    And I create another public market with the following details:
      | name | Deuxième marché    |
      | deadline    | 2025-11-30T23:59:59Z |
      | market_type | services            |
    Then both public markets should be created successfully
    And each public market should have a unique identifier
    And both markets should belong to the same editor

  Scenario: Format de l'identifiant généré
    When I create a public market with the following details:
      | name | Test Market        |
      | deadline    | 2025-12-31T23:59:59Z |
      | market_type | supplies            |
    Then the identifier should match the format "VR-YYYY-XXXXXXXXXXXX"
    And the year part should be the current year
    And the suffix should be a 12-character alphanumeric code

  Scenario: URL de configuration générée correctement
    When I create a public market with the following details:
      | name | Test Market        |
      | deadline    | 2025-12-31T23:59:59Z |
      | market_type | supplies            |
    Then the configuration URL should contain the identifier
    And the configuration URL should use the correct host
    And the configuration URL should point to the buyer configuration page
