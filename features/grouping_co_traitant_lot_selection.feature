# frozen_string_literal: true

Feature: Co-traitant declares their lots

  As a co-traitant of a grouping
  I want to select the lots I commit to among those pre-selected by the mandataire
  So that I can delimit my application

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And the public market has the lots "Lot 1", "Lot 2" and "Lot 3"
    And a candidate application exists for SIRET "73282932000074"
    And a candidate "candidat@example.com" has a valid magic link token
    And I visit the magic link
    And I choose the candidacy mode "groupement"

  @javascript
  Scenario: Only lots pre-selected by the mandataire for the grouping are proposed
    Given I assign "Lot 1" and "Lot 2" to the groupement
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard
    And I visit the co-traitant invitation link for SIRET "80245139600021"
    And I fill in "Veuillez saisir votre adresse email" with "contact@menuiseries-loire.fr"
    And I click on "Recevoir un lien de connexion"
    Then I should be on the sent sessions page
    And I click the link from the latest email
    Then I should be on the co-traitant grouping dashboard
    When I click on "Préparer ma candidature"
    And I click on "Continuer"
    Then I should see "Lot 1"
    And I should see "Lot 2"
    And I should not see "Lot 3"

  @javascript
  Scenario: The next button stays inactive until at least one lot is checked
    Given I assign "Lot 1" and "Lot 2" to the groupement
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard
    And I visit the co-traitant invitation link for SIRET "80245139600021"
    And I fill in "Veuillez saisir votre adresse email" with "contact@menuiseries-loire.fr"
    And I click on "Recevoir un lien de connexion"
    Then I should be on the sent sessions page
    And I click the link from the latest email
    Then I should be on the co-traitant grouping dashboard
    And I click on "Préparer ma candidature"
    And I click on "Continuer"
    Then the lot selection submit button should be disabled
    When I check the lot "Lot 1"
    Then the lot selection submit button should be enabled

  @javascript
  Scenario: Selected lots are declared for this co-traitant only
    Given I assign "Lot 1" and "Lot 2" to the groupement
    And I choose the grouping legal type "conjoint_mandataire_solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard
    And I visit the co-traitant invitation link for SIRET "80245139600021"
    And I fill in "Veuillez saisir votre adresse email" with "contact@menuiseries-loire.fr"
    And I click on "Recevoir un lien de connexion"
    Then I should be on the sent sessions page
    And I click the link from the latest email
    Then I should be on the co-traitant grouping dashboard
    And I click on "Préparer ma candidature"
    And I click on "Continuer"
    When I check the lot "Lot 1"
    And I submit the lot selection
    Then I should see "Préparez votre dossier de candidature"
    When I visit the grouping dashboard as the co-traitant with SIRET "80245139600021"
    Then the co-traitant declared lots column should show "1 lot"

  @javascript
  Scenario: A solidaire grouping skips the lot selection screen entirely
    Given I assign "Lot 1" and "Lot 2" to the groupement
    And I choose the grouping legal type "solidaire"
    And I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard
    And I visit the co-traitant invitation link for SIRET "80245139600021"
    And I fill in "Veuillez saisir votre adresse email" with "contact@menuiseries-loire.fr"
    And I click on "Recevoir un lien de connexion"
    Then I should be on the sent sessions page
    And I click the link from the latest email
    Then I should be on the co-traitant grouping dashboard
    When I click on "Préparer ma candidature"
    And I click on "Continuer"
    Then I should not see "Sélectionnez les lots de votre candidature"
    When I visit the grouping dashboard as the co-traitant with SIRET "80245139600021"
    Then the co-traitant declared lots column should show "Tous les lots"
