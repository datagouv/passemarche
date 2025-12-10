# frozen_string_literal: true

@carif_oref_integration
Feature: CARIF-OREF API Integration (Qualiopi & France Competences)
  En tant que candidat à un marché public
  Je veux voir mes certifications Qualiopi et habilitations France Compétences récupérées automatiquement
  Afin de ne pas avoir à les saisir manuellement

  Background:
    Given a public market with CARIF-OREF fields exists

  Scenario: CARIF-OREF API is called and processes Qualiopi data
    Given the CARIF-OREF API returns Qualiopi certification data
    When I start an application for the CARIF-OREF market
    And I fill in the SIRET for CARIF-OREF application
    And all APIs complete for CARIF-OREF
    Then the market application should have Qualiopi data stored

  Scenario: CARIF-OREF API is called and processes France Competences data
    Given the CARIF-OREF API returns France Competences habilitations
    When I start an application for the CARIF-OREF market
    And I fill in the SIRET for CARIF-OREF application
    And all APIs complete for CARIF-OREF
    Then the market application should have France Competences data stored

  Scenario: CARIF-OREF API failure marks fields for manual input
    Given the CARIF-OREF API returns an error
    When I start an application for the CARIF-OREF market
    And I fill in the SIRET for CARIF-OREF application
    And all APIs complete for CARIF-OREF with failures
    Then the market application should have manual fallback responses for CARIF-OREF
