Feature: Candidate application deletion

  As an authenticated candidate
  I want to delete an in-progress application
  So that I can remove applications I no longer wish to pursue

  Background:
    Given a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And I am authenticated for my application

  Scenario: Delete button is visible for in-progress applications
    When I visit the dashboard
    Then I should see the delete button for my application

  Scenario: Delete button is not visible for transmitted applications
    Given my application has been submitted
    When I visit the dashboard
    Then I should not see the delete button for my application

  Scenario: Clicking delete opens a confirmation modal
    When I visit the dashboard
    And I click the delete button for my application
    Then I should see the deletion confirmation modal

  Scenario: Confirming deletion removes the application and stays on dashboard when other applications exist
    Given a second in-progress application exists for my account
    When I visit the dashboard
    And I click the delete button for my application
    And I confirm the deletion
    Then my application should no longer exist
    And I should be on the dashboard
    And I should see "Votre candidature a bien été supprimée."

  Scenario: Confirming deletion of the last application redirects to home
    When I visit the dashboard
    And I click the delete button for my application
    And I confirm the deletion
    Then my application should no longer exist
    And I should be on the home page
    And I should see "Votre candidature a bien été supprimée."
