Feature: Candidate dashboard

  As an authenticated candidate
  I want to access a list of my applications
  So that I can manage and track them

  Background:
    Given a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And I am authenticated for my application

  Scenario: Unauthenticated candidate is shown the login form
    Given I am not authenticated
    When I visit the dashboard
    Then I should see the authentication form

  Scenario: Authenticated candidate sees the dashboard
    When I visit the dashboard
    Then I should see "Mes candidatures"

  Scenario: Dashboard shows in-progress application
    When I visit the dashboard
    Then I should see my application market name
    And I should see "EN COURS"

  Scenario: Dashboard shows completed application
    Given my application has been submitted
    When I visit the dashboard
    Then I should see my application market name
    And I should see "TRANSMISE"

  Scenario: Dashboard only shows the candidate's own applications
    Given another application exists for a different candidate
    When I visit the dashboard
    Then I should not see the other application market name

  Scenario: Candidate can navigate to edit an in-progress application
    When I visit the dashboard
    And I click "Modifier"
    Then I should be on the first step of my application

  Scenario: Summary tiles display correct counts
    Given my application has been submitted
    And a second in-progress application exists for my account
    When I visit the dashboard
    Then I should see "1" for in-progress count
    And I should see "1" for completed count
