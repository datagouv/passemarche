# frozen_string_literal: true

@motifs_exclusion_attestation
Feature: Motifs d'exclusion attestation display
  En tant qu'acheteur ou candidat
  Je veux voir l'attestation du candidat concernant les motifs d'exclusion
  Afin de vérifier sa déclaration sur l'honneur

  Background:
    Given a public market with motifs_exclusion fields exists
    And a candidate application with attests_no_exclusion_motifs checked

  Scenario: Summary displays candidate attestation block when attests_no_exclusion_motifs is true
    When I visit the summary page for my application
    Then I should see "Les motifs d'exclusion"
    And I should see "atteste sur l'honneur"

  Scenario: Summary displays candidate attestation block when attests_no_exclusion_motifs is false
    Given the candidate has not confirmed the exclusion motifs attestation
    When I visit the summary page for my application
    Then I should see "Les motifs d'exclusion"
    And I should see "attestation sur l'honneur est manquante"
