Feature: Candidate authentication via magic link

  As a candidate
  I want to authenticate via a magic link
  So that I can access my market application securely

  Background:
    Given a public market exists
    And a candidate application exists for SIRET "73282932000074"

  Scenario: Unauthenticated candidate sees the login form
    When I visit the first step of my application
    Then I should see the authentication form
    And I should see "Bienvenue,"

  Scenario: Candidate requests a magic link with valid inputs
    When I visit the first step of my application
    And I fill in "siret" with "73282932000074"
    And I fill in "email" with "candidat@example.com"
    And I submit the session form
    Then I should see "Vérifiez vos emails"
    And an email should have been sent to "candidat@example.com"

  Scenario: Candidate requests a magic link with invalid email
    When I visit the first step of my application
    And I fill in "email" with "not-an-email"
    And I submit the session form
    Then I should see the authentication form
    And I should see an error message

  Scenario: Candidate verifies a valid magic link
    Given a candidate "candidat@example.com" has a valid magic link token
    When I visit the magic link
    Then I should be on the first step of my application
    And I should be authenticated

  Scenario: Candidate reconnects with matching SIRET and email
    Given the candidate application is already assigned to "candidat@example.com"
    When I visit the first step of my application
    And I fill in "siret" with "73282932000074"
    And I fill in "email" with "candidat@example.com"
    And I submit the session form
    Then I should see "Vérifiez vos emails"
    And an email should have been sent to "candidat@example.com"

  Scenario: Candidate reconnects with wrong email
    Given the candidate application is already assigned to "original@example.com"
    When I visit the first step of my application
    And I fill in "siret" with "73282932000074"
    And I fill in "email" with "wrong@example.com"
    And I submit the session form
    Then I should see the authentication form
    And I should see an error message

  Scenario: Reconnected candidate lands on their candidature
    Given the candidate application is already assigned to "candidat@example.com"
    And a candidate "candidat@example.com" has a valid magic link token
    When I visit the magic link
    Then I should be on the first step of my application
    And I should be authenticated

  Scenario: Authenticated candidate email is pre-filled in blank email fields
    Given the public market has an email field in the "contact" step
    And a candidate "candidat@example.com" has a valid magic link token
    When I visit the magic link
    And I navigate to the "contact" step
    Then the email field should be pre-filled with "candidat@example.com"

  Scenario: Submit button is disabled when email is empty
    When I visit the first step of my application
    Then the "Recevoir un lien de connexion" button should be disabled

  Scenario: Pre-fill does not override an already filled email field
    Given the public market has an email field in the "contact" step
    And the candidate application already has "existing@example.com" in the email field
    And a candidate "candidat@example.com" has a valid magic link token
    When I visit the magic link
    And I navigate to the "contact" step
    Then the email field should contain "existing@example.com"
    And the email field should not contain "candidat@example.com"
