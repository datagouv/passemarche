# frozen_string_literal: true

Feature: OAuth2 Authentication pour les Éditeurs
  En tant qu'éditeur de plateforme de marchés publics
  Je veux pouvoir m'authentifier via OAuth2 avec client credentials
  Afin d'accéder aux services de Voie Rapide via API

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"

  Scenario: Éditeur autorisé obtient un token d'accès avec succès
    When I request an OAuth token with valid credentials
    Then I should receive a valid access token
    And the token should expire in 24 hours
    And the token should have "api_access" scope

  Scenario: Éditeur demande un token avec un scope spécifique
    When I request an OAuth token with scope "api_read"
    Then I should receive a valid access token
    And the token should have "api_read" scope

  Scenario: Éditeur demande un token avec plusieurs scopes
    When I request an OAuth token with scope "api_read api_write"
    Then I should receive a valid access token
    And the token should have "api_read api_write" scope

  Scenario: Éditeur non autorisé ne peut pas obtenir de token
    Given an unauthorized editor exists with credentials "unauthorized_id" and "unauthorized_secret"
    When I request an OAuth token with credentials "unauthorized_id" and "unauthorized_secret"
    Then I should receive an "invalid_client" error
    And the response status should be 401

  Scenario: Éditeur inactif ne peut pas obtenir de token
    Given an inactive editor exists with credentials "inactive_id" and "inactive_secret"
    When I request an OAuth token with credentials "inactive_id" and "inactive_secret"
    Then I should receive an "invalid_client" error
    And the response status should be 401

  Scenario: Demande avec des identifiants invalides
    When I request an OAuth token with credentials "invalid_id" and "invalid_secret"
    Then I should receive an "invalid_client" error
    And the response status should be 401

  Scenario: Demande sans grant_type requis
    When I request an OAuth token without grant_type
    Then I should receive an "invalid_request" error
    And the response status should be 400

  Scenario: Demande avec un scope invalide
    When I request an OAuth token with invalid scope "invalid_scope"
    Then I should receive an "invalid_scope" error
    And the response status should be 400

  Scenario: Processus de rafraîchissement de token (nouvelle demande)
    Given I have a valid access token
    When I request a new OAuth token with the same credentials
    Then I should receive a new valid access token
    And the previous token should be revoked
    And the new token should be different from the previous one

  Scenario: Gestion de plusieurs tokens avec scopes différents
    Given I have a token with scope "api_read"
    When I request a new token with scope "api_write"
    Then I should have two different tokens
    And both tokens should be valid
    And each token should have its respective scope

  Scenario: Expiration et renouvellement de token
    Given I have an expired access token
    When I request a new OAuth token with valid credentials
    Then I should receive a new valid access token
    And the new token should be different from the expired one