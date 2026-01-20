# frozen_string_literal: true

@motifs_exclusion_badge_colors
Feature: Badge colors for motifs d'exclusion facultative
  En tant qu'acheteur ou candidat
  Je veux voir un badge de couleur appropriée pour les motifs d'exclusion facultative
  Afin de comprendre rapidement si une réponse est problématique

  Background:
    Given an editor exists
    And a public market with optional motifs exclusion radio fields exists

  Scenario: Error badge when candidate answers Oui to optional exclusion motif
    Given a market application with motifs exclusion answered Oui
    When I visit the candidate summary page
    Then I should see an error badge with text "Oui"

  Scenario: Success badge when candidate answers Non to optional exclusion motif
    Given a market application with motifs exclusion answered Non
    When I visit the candidate summary page
    Then I should see a success badge with text "Non"
