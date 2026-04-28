# frozen_string_literal: true

@attestation_lots
Feature: Lots display in candidate attestation
  En tant que candidat
  Je veux visualiser clairement les lots auxquels je candidate dans mon attestation
  Afin de vérifier l'exactitude de ma candidature avant soumission

  Background:
    Given a public market with lots exists for attestation

  Scenario: Le bloc lots est affiché pour un marché alloti
    Given a candidate has selected lots for the attestation market
    When I visit the attestation summary page
    Then I should see "Liste des lots concernés par la candidature"

  Scenario: Les informations du lot sont affichées
    Given a candidate has selected lots for the attestation market
    When I visit the attestation summary page
    Then I should see "Lot 1"
    And I should see "Titre :"
    And I should see "Type :"

  Scenario: Tous les lots sélectionnés apparaissent
    Given a candidate has selected two lots for the attestation market
    When I visit the attestation summary page
    Then I should see "Lot 1"
    And I should see "Lot 2"

  Scenario: Les lots non sélectionnés n'apparaissent pas
    Given a candidate has selected only the first lot for the attestation market
    When I visit the attestation summary page
    Then I should see "Lot 1"
    And I should not see "Lot 2"

  Scenario: Les lots sont ordonnés par numéro croissant
    Given a candidate has selected two lots for the attestation market
    When I visit the attestation summary page
    Then the lots should appear in ascending order

  Scenario: Le bloc n'est pas affiché pour un marché non alloti
    Given a candidate applies to a market without lots
    When I visit the non-alloti attestation summary page
    Then I should not see "Liste des lots concernés par la candidature"
