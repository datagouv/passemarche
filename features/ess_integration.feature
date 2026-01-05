# frozen_string_literal: true

@ess_integration
Feature: ESS (Economie Sociale et Solidaire) INSEE API Integration
  En tant que candidat a un marche public
  Je veux que mon statut ESS soit recupere automatiquement depuis l'API INSEE
  Afin de ne pas avoir a le saisir manuellement

  Background:
    Given a public market with ESS field exists

  Scenario: API returns ESS true - field is auto-filled with ESS status
    Given the INSEE API returns ESS true
    When I start an application for the ESS market
    And all APIs complete for ESS
    Then the market application should have ESS data with radio_choice yes
    And the ESS response should have source auto

  Scenario: API returns ESS false - field is auto-filled with non-ESS status
    Given the INSEE API returns ESS false
    When I start an application for the ESS market
    And all APIs complete for ESS
    Then the market application should have ESS data with radio_choice no
    And the ESS response should have source auto

  Scenario: API returns ESS null - field is empty for manual input
    Given the INSEE API returns ESS null
    When I start an application for the ESS market
    And all APIs complete for ESS
    Then the market application should not have an ESS response
    And the ESS field should allow manual input

  Scenario: API failure - field is marked for manual input
    Given the INSEE API returns an error
    When I start an application for the ESS market
    And all APIs complete for ESS with failures
    Then the market application should have a manual fallback response for ESS
    And the ESS field should allow manual input
