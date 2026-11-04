Feature: Co-traitant application locked once the grouping is submitted

  As a co-traitant of a grouping
  I want to know that I can no longer modify my application once the grouping is submitted
  So that the submitted file stays consistent

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And this application leads a grouping as mandataire "mandataire@example.com"
    And I am authenticated as a co-traitant of this grouping
    And I have transmitted my form to the mandataire

  Scenario: The co-traitant can still modify their form until the mandataire submits the grouping
    When I visit my co-traitant grouping dashboard
    And I click on "Modifier ma candidature"
    Then I should not see "Vous ne pouvez plus modifier votre candidature"
    When I visit my co-traitant form step "summary"
    And I click on "Candidature terminée - Transmettre au mandataire"
    Then I should see "Votre candidature a été transmise !"
    And "mandataire@example.com" should receive the email "Un co-traitant a fait des modifications"

  Scenario: The co-traitant can no longer modify their form once the grouping is submitted
    Given the mandataire has submitted the grouping
    When I visit my co-traitant grouping dashboard
    Then I should see "Votre candidature a été transmise"
    And I should not see "attestation"
    And I should not see "Modifier ma candidature"
    And I should see "Consulter le formulaire"
    When I visit my co-traitant form step "summary"
    Then I should see "Vous ne pouvez plus modifier votre candidature"
    And I should see "Seul le mandataire peut vous permettre de la modifier."
    And I should not see "attestation"
