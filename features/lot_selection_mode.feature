Feature: Mandataire selects lots and their response mode

  As a mandataire candidate
  I want to choose, for each lot, whether I apply alone, as part of the groupement, or not at all
  So that mixed scenarios are covered

  Background:
    Given the groupement feature flag is enabled
    And a multi-type public market with lots exists
    And a candidate starts a new application for the multi-type market

  @javascript
  Scenario: Mandataire in mixte mode sees the three options per lot
    When I choose the candidacy mode "mixte"
    Then I should see "Sélectionnez les lots pour la candidature"
    And each lot should offer the options "Seul", "En groupement" and "Ne pas répondre"

  @javascript
  Scenario: Mandataire in groupement-only mode sees only two options per lot
    When I choose the candidacy mode "groupement"
    Then each lot should offer the options "En groupement" and "Ne pas répondre"
    And the lot option "Seul" should not be visible

  @javascript
  Scenario: All lots are pre-selected on En groupement by default
    When I choose the candidacy mode "groupement"
    Then every lot should be set to "En groupement"

  @javascript
  Scenario: Continue button is disabled until at least one solo and one groupement lot are set in mixte mode
    When I choose the candidacy mode "mixte"
    And I set lot "Lot 1 - Gros œuvre" to "solo"
    And I set lot "Lot 2 - Charpente" to "solo"
    And I set lot "Lot 3 - Prestations SI" to "solo"
    Then the "Continuer" button should be disabled
    When I set lot "Lot 3 - Prestations SI" to "groupement"
    Then the "Continuer" button should be enabled

  @javascript
  Scenario: Continue button is disabled until at least one lot is set to groupement in groupement-only mode
    When I choose the candidacy mode "groupement"
    And I set lot "Lot 1 - Gros œuvre" to "none"
    And I set lot "Lot 2 - Charpente" to "none"
    And I set lot "Lot 3 - Prestations SI" to "none"
    Then the "Continuer" button should be disabled
    When I set lot "Lot 3 - Prestations SI" to "groupement"
    Then the "Continuer" button should be enabled

  @javascript
  Scenario: The mixed mode banner is shown in mixte mode
    When I choose the candidacy mode "mixte"
    Then I should see "Vous devez sélectionner au moins un lot"

  @javascript
  Scenario: The mixed mode banner is not shown in groupement-only mode
    When I choose the candidacy mode "groupement"
    Then I should not see "Vous devez sélectionner au moins un lot"

  @javascript
  Scenario: Lots are grouped by typology
    When I choose the candidacy mode "groupement"
    Then I should see a section for the lot typology "works"
    And I should see a section for the lot typology "services"

  @javascript
  Scenario: Applying a mode to a whole typology updates every lot of that section
    When I choose the candidacy mode "groupement"
    And I apply "Ne pas répondre" to the typology "works"
    Then every lot of the typology "works" should be set to "Ne pas répondre"
    And every lot of the typology "services" should be set to "En groupement"

  @javascript
  Scenario: A lot can be adjusted individually after a bulk action without affecting the others
    When I choose the candidacy mode "groupement"
    And I apply "Ne pas répondre" to the typology "works"
    And I set lot "Lot 1 - Gros œuvre" to "groupement"
    Then lot "Lot 1 - Gros œuvre" should be set to "En groupement"
    And lot "Lot 2 - Charpente" should be set to "Ne pas répondre"

  @javascript
  Scenario: Mandataire submits the lot selection and reaches the grouping legal type step
    When I choose the candidacy mode "groupement"
    And I set lot "Lot 1 - Gros œuvre" to "groupement"
    And I click on "Continuer"
    Then I should be on the grouping legal type step

  @javascript
  Scenario: Mandataire goes back from the grouping legal type step to review the lot selection
    When I choose the candidacy mode "groupement"
    And I set lot "Lot 1 - Gros œuvre" to "groupement"
    And I click on "Continuer"
    And I should be on the grouping legal type step
    And I click on "Précédent"
    Then I should see "Sélectionnez les lots pour la candidature"
    And lot "Lot 1 - Gros œuvre" should be set to "En groupement"

  @javascript
  Scenario: Mandataire in mixte mode still reaches lot selection when revisiting the read-only candidacy mode from the solo side
    When I choose the candidacy mode "mixte"
    Then I should see "Sélectionnez les lots pour la candidature"
    When I visit the read-only candidacy mode step of the solo application
    Then I should see "Comment souhaitez-vous candidater ?"
    When I click on "Continuer"
    Then I should see "Sélectionnez les lots pour la candidature"
