Feature: Access control on the grouping dashboard

  As a candidate without a grouping
  I do not want to access the grouping dashboard of another candidacy
  So that my data stays private

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"

  Scenario: A candidate without any grouping cannot access the dashboard
    Given I am authenticated for my application
    When I visit the grouping dashboard directly
    Then I should be on the candidacy mode choice step
