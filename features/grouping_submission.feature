Feature: Mandataire submits the grouping candidacy

  As a mandataire candidate
  I want to submit my grouping candidacy, complete or partial
  So that it is transmitted to the buyer before the deadline

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And the editor has a working webhook configured
    And a candidate application exists for SIRET "73282932000074"
    And a candidate "candidat@example.com" has a valid magic link token
    And I visit the magic link
    And I choose the candidacy mode "groupement"
    And I choose the grouping legal type "conjoint_mandataire_solidaire"

  @javascript
  Scenario: Submit button is disabled while a member is not completed
    Given a co-traitant of the grouping is in progress
    When I visit the grouping dashboard
    Then the "Soumettre la candidature" button should be disabled

  @javascript
  Scenario: Submit button becomes active once every member is completed
    Given every member of the grouping is completed
    When I visit the grouping dashboard
    Then the "Soumettre la candidature" button should be enabled
    And I should not see "Soumettre sans la totalité des candidatures"

  @javascript
  Scenario: Full submission redirects to the confirmation screen
    Given every member of the grouping is completed
    When I visit the grouping dashboard
    And I click on "Soumettre la candidature"
    Then I should see "La candidature a été transmise à la plateforme de marché !"

  @javascript
  Scenario: Partial submission modal shows the DAJ wording and can be cancelled
    Given a co-traitant of the grouping is in progress
    When I visit the grouping dashboard
    And I click on "Soumettre sans la totalité des candidatures"
    Then I should see "Soumettre sans la candidature de tous les co-traitants ?"
    And I should see "article R. 2144-7 du code de la commande publique"
    When I click on "Annuler"
    Then the grouping should not be submitted

  @javascript
  Scenario: Confirming the partial submission modal submits the grouping
    Given a co-traitant of the grouping is in progress
    When I visit the grouping dashboard
    And I click on "Soumettre sans la totalité des candidatures"
    And I click on "Confirmer la soumission"
    Then I should see "La candidature a été transmise à la plateforme de marché !"
    And the grouping should be submitted

  # L'email "Candidature transmise à l'acheteur" à chaque co-traitant est reporté à FAS-582 :
  # aucun mailer de soumission groupement n'existe encore, hors scope de FAS-574.

  @javascript
  Scenario: Partial submission is not proposed until at least one member has started
    When I add a co-traitant with SIRET "80245139600021" and email "contact@menuiseries-loire.fr"
    And I click on "Continuer"
    And I click on "Confirmer et envoyer les invitations"
    Then I should not see "Soumettre sans la totalité des candidatures"
    And the "Soumettre la candidature" button should be disabled
