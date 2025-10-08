@radio_with_justification_required
Feature: Radio with justification required field
  En tant que candidat à un marché public
  Je veux pouvoir répondre à une question de conformité avec un choix oui/non
  Où "non" nécessite un document justificatif obligatoire
  Et "oui" permet de fournir des informations optionnelles
  Afin de démontrer ma conformité ou de justifier ma non-conformité

  Background:
    Given a public market with radio_with_justification_required field exists
    And a candidate starts an application for this market justification

  Scenario: Submit with "No" and no document (INVALID)
    When I visit the justification field step
    And I select the "No" radio button for justification
    And I click "Suivant"
    Then the justification form should fail validation
    And I should see a document required error

  Scenario: Submit with "No" and document (VALID)
    When I visit the justification field step
    And I select the "No" radio button for justification
    And I attach a justification file "justification.pdf"
    And I click "Suivant"
    Then the justification form should be submitted successfully
    And the justification radio choice should be "no"
    And the justification response should have 1 attached file

  Scenario: Submit with "Yes" and no additional data (VALID)
    When I visit the justification field step
    And I select the "Yes" radio button for justification
    And I click "Suivant"
    Then the justification form should be submitted successfully
    And the justification radio choice should be "yes"

  Scenario: Submit with "Yes" and text only (VALID)
    When I visit the justification field step
    And I select the "Yes" radio button for justification
    And I fill in the justification text field with "Nous sommes en conformité totale"
    And I click "Suivant"
    Then the justification form should be submitted successfully
    And the justification response should contain text "Nous sommes en conformité totale"

  Scenario: Submit with "Yes" and file only (VALID)
    When I visit the justification field step
    And I select the "Yes" radio button for justification
    And I attach a justification file "supporting.pdf"
    And I click "Suivant"
    Then the justification form should be submitted successfully
    And the justification response should have 1 attached file

  Scenario: Submit with "Yes" and both text and file (VALID)
    When I visit the justification field step
    And I select the "Yes" radio button for justification
    And I fill in the justification text field with "Voir document joint"
    And I attach a justification file "proof.pdf"
    And I click "Suivant"
    Then the justification form should be submitted successfully
    And the justification response should contain text "Voir document joint"
    And the justification response should have 1 attached file
