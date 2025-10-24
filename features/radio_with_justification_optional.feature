@radio_with_justification_optional
Feature: Radio with justification optional field
  En tant que candidat à un marché public
  Je veux pouvoir répondre à une question de conformité avec un choix oui/non
  Où "non" permet de fournir un document justificatif optionnel
  Et "oui" permet de fournir des informations optionnelles
  Afin de démontrer ma conformité ou de justifier ma non-conformité

  Background:
    Given a public market with radio_with_justification_optional field exists
    And a candidate starts an application for this market optional justification

  Scenario: Submit with "No" and no document (VALID - key difference from required)
    When I visit the optional justification field step
    And I select the "No" radio button for optional justification
    And I click "Suivant"
    Then the optional justification form should be submitted successfully
    And the optional justification radio choice should be "no"
    And the optional justification response should have 0 attached files

  Scenario: Submit with "No" and document (VALID)
    When I visit the optional justification field step
    And I select the "No" radio button for optional justification
    And I attach an optional justification file "justification.pdf"
    And I click "Suivant"
    Then the optional justification form should be submitted successfully
    And the optional justification radio choice should be "no"
    And the optional justification response should have 1 attached file

  Scenario: Submit with "Yes" and no additional data (VALID)
    When I visit the optional justification field step
    And I select the "Yes" radio button for optional justification
    And I click "Suivant"
    Then the optional justification form should be submitted successfully
    And the optional justification radio choice should be "yes"

  Scenario: Submit with "Yes" and text only (VALID)
    When I visit the optional justification field step
    And I select the "Yes" radio button for optional justification
    And I fill in the optional justification text field with "Nous sommes en conformité totale"
    And I click "Suivant"
    Then the optional justification form should be submitted successfully
    And the optional justification response should contain text "Nous sommes en conformité totale"

  Scenario: Submit with "Yes" and both text and file (VALID)
    When I visit the optional justification field step
    And I select the "Yes" radio button for optional justification
    And I fill in the optional justification text field with "Voir document joint"
    And I attach an optional justification file "proof.pdf"
    And I click "Suivant"
    Then the optional justification form should be submitted successfully
    And the optional justification response should contain text "Voir document joint"
    And the optional justification response should have 1 attached file
