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
    And I click "Recevoir un lien de connexion"
    Then I should see "Vérifiez vos emails"
    And an email should have been sent to "candidat@example.com"

  Scenario: Candidate requests a magic link with invalid email
    When I visit the first step of my application
    And I fill in "email" with "not-an-email"
    And I click "Recevoir un lien de connexion"
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
    And I click "Recevoir un lien de connexion"
    Then I should see "Vérifiez vos emails"
    And an email should have been sent to "candidat@example.com"

  Scenario: Candidate reconnects with wrong email
    Given the candidate application is already assigned to "original@example.com"
    When I visit the first step of my application
    And I fill in "siret" with "73282932000074"
    And I fill in "email" with "wrong@example.com"
    And I click "Recevoir un lien de connexion"
    Then I should see the authentication form
    And I should see an error message

  Scenario: Reconnected candidate lands on their candidature
    Given the candidate application is already assigned to "candidat@example.com"
    And a candidate "candidat@example.com" has a valid magic link token
    When I visit the magic link
    Then I should be on the first step of my application
    And I should be authenticated

  Scenario: Candidate with multiple applications authenticates for the correct one
    Given a second candidate application exists for SIRET "73282932000074"
    When I visit the first step of my second application
    And I fill in "siret" with "73282932000074"
    And I fill in "email" with "candidat@example.com"
    And I click "Recevoir un lien de connexion"
    Then I should see "Vérifiez vos emails"
    And an email should have been sent to "candidat@example.com"

  Scenario: Authenticated candidate is required to re-authenticate for a different application
    Given a second candidate application exists for SIRET "73282932000074"
    And I am authenticated for my application
    When I visit the first step of my second application
    Then I should see the authentication form
