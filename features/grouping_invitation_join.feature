Feature: Co-traitant joins a grouping from their invitation

  As a co-traitant invited to a grouping
  I want to click my invitation link and identify myself
  So that I can prepare my candidacy

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And a candidate "candidat@example.com" has a valid magic link token
    And I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"

  @javascript
  Scenario: A co-traitant joins the grouping and sees the shared dashboard
    When I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard

    When I visit the co-traitant invitation link for SIRET "80245139600021"
    Then the SIRET field should be pre-filled with "80245139600021" and locked

    When I fill in "Veuillez saisir votre adresse email" with "contact@menuiseries-loire.fr"
    And I click on "Recevoir un lien de connexion"
    Then I should be on the sent sessions page
    When I click the link from the latest email
    Then I should be on the co-traitant grouping dashboard
    And I should see "VOUS : CO-TRAITANT"
    And I should see the action "Préparer ma candidature" on my own row

  @javascript
  Scenario: A co-traitant cannot request a magic link with an email that does not match the invitation
    When I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard

    When I visit the co-traitant invitation link for SIRET "80245139600021"
    And I fill in "Veuillez saisir votre adresse email" with "attacker@example.com"
    And I click on "Recevoir un lien de connexion"
    Then I should see an error message

  @javascript
  Scenario: The co-traitant sees no management action on other members
    When I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should be on the grouping dashboard

    When I visit the co-traitant invitation link for SIRET "80245139600021"
    And I fill in "Veuillez saisir votre adresse email" with "contact@menuiseries-loire.fr"
    And I click on "Recevoir un lien de connexion"
    Then I should be on the sent sessions page

    When I click the link from the latest email
    Then I should be on the co-traitant grouping dashboard
    And I should not see "Modifier les membres"
    And the mandataire row should show no action
