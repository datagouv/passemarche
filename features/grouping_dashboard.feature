Feature: Mandataire follows up and submits the grouping candidacies

  As a mandataire candidate
  I want a single dashboard to follow up on my co-traitants and submit my grouping candidacy
  So that I know when everyone is ready

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And a candidate "candidat@example.com" has a valid magic link token
    And I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"

  @javascript
  Scenario: Mandataire is redirected to the dashboard after confirming the composition
    When I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard
    And I should see "Les membres du groupement"

  @javascript
  Scenario: An invited co-traitant offers relaunch and copy link actions
    When I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then the co-traitant "80245139600021" should have status "Invité"
    And the co-traitant "80245139600021" should have the action "Relancer"
    And the co-traitant "80245139600021" should have the action "Copier le lien"

  @javascript
  Scenario: The submission section shows the pending state until every member is completed
    When I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should see "Co-traitants en attente"

  @javascript
  Scenario: The submission section becomes ready once every member is completed
    Given every member of the grouping is completed
    When I visit the grouping dashboard
    Then I should see "Tous les membres ont complété leur candidature"

  @javascript
  Scenario: Partial submission is proposed once at least one member has started
    Given a co-traitant of the grouping is in progress
    When I visit the grouping dashboard
    Then I should see "Soumettre sans la totalité des candidatures"

  @javascript
  Scenario: A mandataire with a mixed candidacy sees two distinct blocks
    Given the candidate application also has a solo counterpart on the same market
    When I visit the grouping dashboard
    Then I should see "Candidature individuelle"
    And I should see "Candidature en groupement"

  @javascript
  Scenario: Lots declared by a co-traitant only appear in their own row
    Given a co-traitant of the grouping declared the lot "Lot 1"
    When I visit the grouping dashboard
    Then the lots section should not show "Lot 1"
    And the co-traitant declared lots column should show "1 lot"

