# frozen_string_literal: true

@motifs_exclusion_accordion
Feature: Motifs d'exclusion - accordéon et liens articles
  En tant que candidat
  Je veux comprendre clairement les motifs d'exclusion
  Afin d'éviter toute erreur lors de ma candidature

  Background:
    Given a public market with motifs_exclusion fields exists
    And a candidate application with attests_no_exclusion_motifs checked
    And I visit the attestation motifs exclusion page for my application

  Scenario: Article references are displayed as clickable links
    Then I should see a link "Art. L.2141-1 à L.2141-5"
    And I should see a link "Art. L.2141-7 à L.2141-10"

  Scenario: Article links open in a new tab
    Then the article link "Art. L.2141-1 à L.2141-5" should open in a new tab
    And the article link "Art. L.2141-7 à L.2141-10" should open in a new tab

  Scenario: The accordion is closed by default
    Then the motifs exclusion accordion should be closed

  Scenario: No detailed content is visible when the accordion is closed
    Then the motifs exclusion accordion details should not be visible

  Scenario: All 6 sections are present in the accordion content
    Then the accordion content should include "Principe"
    And the accordion content should include "Condamnations pénales visées"
    And the accordion content should include "Situation de l'entreprise"
    And the accordion content should include "Manquements fiscaux"
    And the accordion content should include "Présomption d'entente"
    And the accordion content should include "Conflit d'intérêt"

  Scenario: Condemnation motifs are displayed as tags
    Then the accordion content should have a tag "Corruption passive"
    And the accordion content should have a tag "Blanchiment"

  Scenario: Condemnation tags are not clickable
    Then the condemnation tags should not be links
