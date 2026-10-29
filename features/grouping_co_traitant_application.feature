Feature: Co-traitant fills in and transmits their part

  As a co-traitant of a grouping
  I want to fill in my application form, save it as a draft and transmit it
  So that the mandataire can submit the grouping candidacy

  Background:
    Given the groupement feature flag is enabled
    And a public market exists
    And a candidate application exists for SIRET "73282932000074"
    And this application leads a grouping as mandataire "mandataire@example.com"
    And I am authenticated as a co-traitant of this grouping

  Scenario: The co-traitant saves a step as draft and lands on the grouping dashboard
    When I visit my co-traitant form step "exclusion_criteria"
    And I click on "Sauvegarder en brouillon"
    Then I should be on the co-traitant grouping dashboard
    And I should see "Votre brouillon a été sauvegardé."

  Scenario: The co-traitant finds their draft again when coming back to the form
    Given the market asks for a text field "draft_note" in the "economic_capacities" step
    When I visit my co-traitant form step "economic_capacities"
    And I fill in the "draft_note" field with "Saisie gardée en brouillon"
    And I click on "Sauvegarder en brouillon"
    Then I should be on the co-traitant grouping dashboard
    When I visit my co-traitant form step "economic_capacities"
    Then the "draft_note" field should contain "Saisie gardée en brouillon"

  Scenario: The co-traitant transmits their form to the mandataire
    When I visit my co-traitant form step "summary"
    Then I should see "Précédent"
    When I click on "Candidature terminée - Transmettre au mandataire"
    Then I should see "Votre candidature a été transmise !"
    And I should not see "attestation"
    And "mandataire@example.com" should receive the email "Un co-traitant a complété son formulaire"
    When I click on "Revenir sur le suivi du groupement"
    Then I should be on the co-traitant grouping dashboard
    And the co-traitant "80245139601003" should have status "Complété"

  Scenario: The co-traitant only sees the documents of the lot types they declared
    Given the market has a works lot and a services lot
    And the market asks for a works text field "certificat_qualibat" in the "economic_capacities" step
    And the market asks for a services text field "certificat_qualiopi" in the "economic_capacities" step
    And I declared only the services lot
    When I visit my co-traitant form step "economic_capacities"
    Then I should see the "certificat_qualiopi" field
    And I should not see the "certificat_qualibat" field
