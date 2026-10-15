Feature: Mandataire defines the grouping legal type

  As a mandataire candidate
  I want to choose the legal type of my groupement
  So that the composition and responsibilities of the groupement are clear

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And a candidate "candidat@example.com" has a valid magic link token

  @javascript
  Scenario: Mandataire sees the grouping legal type choice screen after choosing groupement
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    Then I should see "Le type de groupement"
    And I should see "Conjoint"
    And I should see "Solidaire"
    And I should see "Conjoint + mandataire solidaire"

  @javascript
  Scenario: Continue button is disabled until a legal type is chosen
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    Then the "Continuer" button should be disabled

  @javascript
  Scenario: Mandataire chooses the legal type of the groupement
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    Then I should be on the grouping composition step
    And the grouping legal type should be "conjoint_mandataire_solidaire"

  Scenario: A candidate who is not mandataire of a grouping cannot access the screen
    Given I am authenticated for my application
    When I visit the grouping legal type step directly
    Then I should be on the candidacy mode choice step

  @javascript
  Scenario: Candidate logs in again before choosing the legal type
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    Then I should see "Le type de groupement"
    When I visit the magic link
    Then I should be on the grouping legal type step

  @javascript
  Scenario: Mandataire goes back to see the chosen candidacy mode in read-only
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I click on "Précédent"
    Then I should see "Comment souhaitez-vous candidater ?"
    And the candidacy mode "groupement" should be checked and disabled

  @javascript
  Scenario: The legal type is read-only once the invitations have been sent
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard
    When I visit the grouping legal type step directly
    Then the grouping legal type choices should be disabled
    When I click on "Continuer"
    Then the grouping legal type should be "conjoint"
