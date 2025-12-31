# frozen_string_literal: true

@motifs_exclusion_contestation
Feature: Composant bloc de contestation motifs d'exclusion
  En tant que candidat
  Je veux voir le bloc de contestation pour un motif d'exclusion détecté
  Afin de pouvoir fournir une explication ou un justificatif

  Background:
    Given a public market with motifs_exclusion fields exists
    And a candidate application with attests_no_exclusion_motifs checked
    And a Bodacc exclusion motif exists for the candidate
    When I visit the attestation motifs exclusion page for my application

  Scenario: Display contestation block
    Then I should see "Procédure de liquidation judiciaire"
    And I should see "Je souhaite fournir des informations complémentaires"

  Scenario: Use contestation form
    When I click the contestation button
    Then I should see the contestation form
    When I fill in the contestation form with a file and text
