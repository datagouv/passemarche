# frozen_string_literal: true

@api_publish_market
Feature: Publication d'un marché via l'API
  En tant que plateforme de marchés publics
  Je veux pouvoir signaler la publication d'une consultation
  Afin de verrouiller la configuration du marché

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token

  Scenario: CA-6 - Publier un marché complété verrouille immédiatement la configuration
    Given a completed market exists for the current editor with identifier "VR-2026-PUBLISH001"
    When I publish the market "VR-2026-PUBLISH001"
    Then the response status should be 200
    And the market "VR-2026-PUBLISH001" should be published

  Scenario: Échec de publication d'un marché non complété
    Given a public market exists for the current editor with identifier "VR-2026-PUBLISH002"
    When I publish the market "VR-2026-PUBLISH002"
    Then the response status should be 422
    And the response should contain the error "Le marché n'a pas encore été configuré."

  Scenario: Échec de publication d'un marché déjà publié
    Given a published market exists for the current editor with identifier "VR-2026-PUBLISH003"
    When I publish the market "VR-2026-PUBLISH003"
    Then the response status should be 422
    And the response should contain the error "Le marché a déjà été publié."

  Scenario: Échec de publication sans token d'authentification
    Given a completed market exists for the current editor with identifier "VR-2026-PUBLISH004"
    And I do not have an access token
    When I publish the market "VR-2026-PUBLISH004"
    Then the response status should be 401
