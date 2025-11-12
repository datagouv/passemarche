# frozen_string_literal: true

@urssaf_attestation_vigilance
Feature: Récupération automatique de l'attestation de vigilance URSSAF
  En tant que candidat à un marché public
  Je veux que l'API URSSAF récupère automatiquement mon attestation de vigilance
  Afin de simplifier ma démarche administrative

  Background:
    Given a market attribute exists for URSSAF attestation vigilance
    And a market attribute exists for URSSAF travailleurs handicapés
    And a candidate starts an application for this market (urssaf)

  @with_api
  Scenario: Récupération réussie de l'attestation URSSAF (cotisations sociales)
    Given the URSSAF API will return a valid attestation
    When the API fetches my URSSAF data automatically
    When I visit the exclusion step
    Then I should see the URSSAF fields with API data available
    Then I should see the attestation documents are downloaded
    And the fields should be marked as completed from API

  @with_api
  Scenario: Récupération réussie de l'attestation URSSAF (travailleurs handicapés)
    Given the URSSAF API will return a valid attestation
    When the API fetches my URSSAF data automatically
    When I visit the exclusion step
    Then I should see the URSSAF fields with API data available
    Then I should see the attestation documents are downloaded
    And the fields should be marked as completed from API

  @without_api
  Scenario: Saisie manuelle quand l'API n'est pas disponible (cotisations sociales)
    Given the URSSAF API is not available
    When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
    And I should be able to complete the field manually
    And I should be able to upload supporting documents

  @without_api
  Scenario: Saisie manuelle quand l'API n'est pas disponible (travailleurs handicapés)
    Given the URSSAF API is not available
    When I visit the exclusion motifs step for "obligations_fisciales_et_sociales"
    And I should be able to complete the field manually
    And I should be able to upload supporting documents

  @with_api
  Scenario: Erreur technique de l'API URSSAF (cotisations sociales)
    Given the URSSAF API will return an error
    When I visit the exclusion motifs step for "obligations_fisciales_et_sociales"
    And the API attempts to fetch my URSSAF data
    Then I should be able to complete the field manually

  @with_api
  Scenario: Erreur technique de l'API URSSAF (travailleurs handicapés)
    Given the URSSAF API will return an error
    When I visit the exclusion motifs step for "obligations_fisciales_et_sociales"
    And the API attempts to fetch my URSSAF data
    Then I should be able to complete the field manually
