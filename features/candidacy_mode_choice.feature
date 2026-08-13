Feature: Candidate chooses their candidacy mode

  As a candidate
  I want to choose whether I apply alone, as part of a groupement, or both
  So that the right candidacy flow is initiated

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And a candidate "candidat@example.com" has a valid magic link token

  Scenario: Candidate sees the candidacy mode choice screen after login
    When I visit the magic link
    Then I should see "Comment souhaitez-vous candidater ?"
    And I should see "Candidater seul"
    And I should see "Candidater en groupement"
    And I should see "Candidater seul et en groupement"

  @javascript
  Scenario: Continue button is disabled until a mode is chosen
    When I visit the magic link
    Then the "Continuer" button should be disabled

  @javascript
  Scenario: Candidate chooses to apply alone
    When I visit the magic link
    And I choose the candidacy mode "solo"
    Then I should be on the company identification step
    And my application mode should be "solo"

  @javascript
  Scenario: Candidate chooses to apply as a groupement
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    Then I should be on the company identification step
    And my application mode should be "groupement"
    And I should be the mandataire of a new groupement

  @javascript
  Scenario: Candidate chooses to apply both solo and as a groupement
    When I visit the magic link
    And I choose the candidacy mode "mixte"
    Then I should land on the company identification step of the groupement application
    And my application mode should be "solo"
    And a second market application should exist with mode "groupement"

  Scenario: The choice screen is never shown again once a mode is chosen
    Given the candidate application already has the mode "solo"
    When I visit the magic link
    Then I should be on the company identification step
    And I should not see "Comment souhaitez-vous candidater ?"

  Scenario: A SIRET already mandataire of a groupement on this market cannot start another one
    Given the SIRET is already mandataire of a groupement on this market
    When I visit the magic link
    Then I should see "Vous êtes déjà mandataire d'un groupement sur ce marché"
    And the candidacy mode "groupement" should be disabled
    And the candidacy mode "mixte" should be disabled

  Scenario: The choice screen is not shown when the groupement feature flag is disabled
    Given the groupement feature flag is disabled
    When I visit the magic link
    Then I should be on the company identification step
    And I should not see "Comment souhaitez-vous candidater ?"
