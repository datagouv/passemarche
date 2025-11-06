# frozen_string_literal: true

@dgfip_hybrid_mode
Feature: Mode hybride DGFIP chiffres d'affaires
  En tant que candidat à un marché public
  Je veux que l'API DGFIP pré-remplisse mes chiffres d'affaires et dates
  Mais que je puisse saisir manuellement les pourcentages de marché
  Afin d'avoir une expérience utilisateur optimale

  Background:
    Given a market attribute exists for chiffre affaires global annuel
    And a candidate starts an application for this market

  @with_api
  Scenario: Mode hybride avec API DGFIP
    Given the DGFIP API will return valid chiffres d'affaires data
    When I visit the economic capacities step
    Then I should see DGFIP data with badges and icons correctly displayed
    And I should see empty market percentage fields that I can edit
    When I fill in the market percentages:
      | year   | percentage |
      | year_1 | 75         |
      | year_2 | 80         |
      | year_3 | 70         |
    And I click "Suivant"
    Then the economic capacity form should be submitted successfully
    And the data should have both API data and manual percentages
