Feature: Mandataire composes the grouping and sends invitations

  As a mandataire candidate
  I want to add my co-traitants (SIRET + email) and confirm the composition
  So that invitations are sent to them

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And a candidate "candidat@example.com" has a valid magic link token

  @javascript
  Scenario: Mandataire sees the grouping composition screen
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    Then I should see "Les membres du groupement"
    And I should see "MANDATAIRE" in the members table

  @javascript
  Scenario: Add button is disabled until both fields are filled
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    Then the "Ajouter au groupement" button should be disabled

  @javascript
  Scenario: Continue link is disabled until at least one co-traitant is added
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    Then the "Continuer" link should be disabled

  @javascript
  Scenario: Mandataire adds a valid co-traitant
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    Then I should see "80245139600021" in the members table
    And the co-traitant "80245139600021" status should be "NON ENVOYÉ"
    And the "Continuer" link should be enabled

  @javascript
  Scenario: Mandataire cannot add a co-traitant with an invalid SIRET
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "0000000000" and email "contact@menuiseries-loire.fr"
    Then I should see an error about the SIRET
    And the email field should still contain "contact@menuiseries-loire.fr"

  @javascript
  Scenario: Mandataire cannot add a co-traitant with their own SIRET
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "73282932000074" and email "contact@menuiseries-loire.fr"
    Then I should see an error about the SIRET

  @javascript
  Scenario: Mandataire cannot add the same SIRET twice
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I add a co-traitant with SIRET "80245139600021" and email "other@menuiseries-loire.fr"
    Then I should see an error about the SIRET

  @javascript
  Scenario: Mandataire cannot add a co-traitant with an invalid email
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "not-an-email"
    Then I should see an error about the email
    And the SIRET field should still contain "80245139600021"

  @javascript
  Scenario: Mandataire removes a co-traitant before confirmation
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I remove the co-traitant "80245139600021"
    Then I should not see "80245139600021" in the members table

  @javascript
  Scenario: Mandataire confirms the composition and invitations are sent
    When I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    Then I should see "Récapitulatif du groupement"
    When I click on "Confirmer et envoyer les invitations"
    Then I should see "Le groupement a été créé et les invitations ont été envoyées"
    And an invitation email should have been sent for the co-traitant "80245139600021"

  Scenario: A candidate who is not mandataire of a grouping cannot access the composition screen
    Given I am authenticated for my application
    When I visit the grouping composition step directly
    Then I should be on the candidacy mode choice step
