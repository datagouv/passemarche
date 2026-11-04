Feature: Candidate application consultation

  As an authenticated candidate
  I want to consult a submitted application
  So that I can review the information I submitted

  Background:
    Given a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And my application has been submitted
    And I am authenticated for my application

  Scenario: Unauthenticated candidate is shown the login form
    Given I am not authenticated
    When I visit the consultation page for my application
    Then I should see the authentication form

  Scenario: Authenticated candidate sees the consultation page
    When I visit the consultation page for my application
    Then I should see my application market name
    And I should see "TRANSMISE"

  Scenario: Consultation page shows a link back to the dashboard
    When I visit the consultation page for my application
    Then I should see "Retour à mes candidatures"

  Scenario: Consultation page shows the attestation download button when available
    Given my application has an attestation
    When I visit the consultation page for my application
    Then I should see "Télécharger l'attestation de candidature"

  Scenario: Consultation page does not show the attestation button when not available
    When I visit the consultation page for my application
    Then I should not see "Télécharger l'attestation de candidature"

  Scenario: In-progress application cannot be consulted
    Given I have an in-progress application
    When I visit the consultation page for the in-progress application
    Then I should be on the dashboard
