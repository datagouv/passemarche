# frozen_string_literal: true

@candidate_flow_soft_deleted
Feature: Candidate Flow with Soft-Deleted Market Attributes
  En tant que candidat
  Quand je postule à un marché dont certains attributs ont été supprimés après sa création
  Alors je devrais voir tous les attributs (actifs et supprimés)
  Et pouvoir compléter ma candidature normalement

  Background:
    Given an editor "test_editor" exists
    And a public market with soft-deletable attributes exists

  Scenario: Candidate sees soft-deleted attributes in their application form
    Given a candidate starts an application for the market
    When I visit the company identification step
    And I fill in the SIRET with "73282932000074"
    And I click "Continuer"
    Then I should be on the "api_data_recovery_status" step

    When I click "Continuer"
    Then I should be on the "market_information" step

    When I click "Suivant"
    Then I should be on the "contact" step
    And I should see a field with key "active_field_1"
    And I should see a field with key "to_be_deleted_field"
    And I should see a field with key "active_field_2"

    When the market attribute "to_be_deleted_field" is soft-deleted
    And I reload the page
    Then I should be on the "contact" step
    And I should see a field with key "active_field_1"
    And I should see a field with key "to_be_deleted_field"
    And I should see a field with key "active_field_2"

    When I fill in the field with key "active_field_1" with "Value 1"
    And I fill in the field with key "to_be_deleted_field" with "Value 2"
    And I fill in the field with key "active_field_2" with "Value 3"
    And I click "Suivant"
    Then I should be on the "summary" step
    And I should not see validation errors
