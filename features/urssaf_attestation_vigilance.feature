# frozen_string_literal: true

@urssaf_attestation_vigilance
Feature: Récupération automatique de l'attestation de vigilance URSSAF
  En tant que candidat à un marché public
  Je veux que l'API URSSAF récupère automatiquement mon attestation de vigilance
  Afin de simplifier ma démarche administrative

  Background:
    Given a market attribute exists for URSSAF attestation vigilance
    And a market attribute exists for URSSAF travailleurs handicapés
    And a candidate starts an application for this market

  @with_api
  Scenario: Récupération réussie de l'attestation URSSAF (cotisations sociales)
    Given the URSSAF API will return a valid attestation
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
  Then I should see the URSSAF fields with API data available
  When the API fetches my URSSAF data automatically
  Then I should see the attestation documents are downloaded
  And the fields should be marked as completed from API
  And I should see the attestation filenames displayed

  @with_api
  Scenario: Récupération réussie de l'attestation URSSAF (travailleurs handicapés)
    Given the URSSAF API will return a valid attestation
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
  Then I should see the URSSAF fields with API data available
  When the API fetches my URSSAF data automatically
  Then I should see the attestation documents are downloaded
  And the fields should be marked as completed from API
  And I should see the attestation filenames displayed

  @with_api
  Scenario: Entreprise non à jour de ses cotisations - refus de délivrance (cotisations sociales)
    Given the URSSAF API will return a refusal status
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
    And the API attempts to fetch my URSSAF data
    Then I should see an indication that no attestation is available
    And I should be able to upload a document manually
    And I should be able to provide a justification

  @with_api
  Scenario: Entreprise non à jour de ses cotisations - refus de délivrance (travailleurs handicapés)
    Given the URSSAF API will return a refusal status
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
    And the API attempts to fetch my URSSAF data
    Then I should see an indication that no attestation is available
    And I should be able to upload a document manually
    And I should be able to provide a justification

  @without_api
  Scenario: Saisie manuelle quand l'API n'est pas disponible (cotisations sociales)
    Given the URSSAF API is not available
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
    And I should be able to select "Non" for the exclusion question
    And I should be able to upload supporting documents
    And I should be able to provide written justification

  @without_api
  Scenario: Saisie manuelle quand l'API n'est pas disponible (travailleurs handicapés)
    Given the URSSAF API is not available
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
    And I should be able to select "Non" for the exclusion question
    And I should be able to upload supporting documents
    And I should be able to provide written justification

  @with_api
  Scenario: Erreur technique de l'API URSSAF (cotisations sociales)
    Given the URSSAF API will return an error
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
    And the API attempts to fetch my URSSAF data
    Then I should see a fallback to manual entry
    And I should be able to complete the field manually

  @with_api
  Scenario: Erreur technique de l'API URSSAF (travailleurs handicapés)
    Given the URSSAF API will return an error
  When I visit the exclusion motifs step for "obligations_fiscales_et_sociales"
    And the API attempts to fetch my URSSAF data
    Then I should see a fallback to manual entry
    And I should be able to complete the field manually
