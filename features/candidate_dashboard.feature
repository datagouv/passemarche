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
    And I should see "En cours"

  Scenario: Dashboard shows completed application
    Given my application has been submitted
    When I visit the dashboard
    Then I should see my application market name
    And I should see "Transmise à la plateforme"

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

  Scenario: Dashboard shows buyer name when present
    Given the public market has a buyer name "Ville de Paris"
    When I visit the dashboard
    Then I should see "Ville de Paris"

  Scenario: Dashboard shows an individual application
    When I visit the dashboard
    Then I should see "Candidature individuelle"

  Scenario: Dashboard shows a co-traitant application
    Given my application is a co-traitant of a grouping
    When I visit the dashboard
    Then I should see "Candidature en groupement · Co-traitant"
    And I should see "Modifier"
    And I should see "Mandataire : 41816609600069"

  Scenario: Dashboard shows a co-traitant application as transmitted once the grouping is submitted
    Given my application is a co-traitant of a grouping
    And the grouping has been submitted
    When I visit the dashboard
    Then I should see "Transmise à la plateforme"

  Scenario: Dashboard groups individual and grouping applications of the same market
    Given I also apply as mandataire of a grouping on the same market
    When I visit the dashboard
    Then I should see a single card for my application market
    And the market card should list "Candidature en groupement · Mandataire" then "Candidature individuelle"
    And I should see "2" for in-progress count

  Scenario: Dashboard shows an application whose deadline has passed before transmission
    Given la date limite du marché est dépassée
    When I visit the dashboard
    Then I should see "Date limite dépassée"
    And I should not see "Modifier"
