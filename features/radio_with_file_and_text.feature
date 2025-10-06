@radio_with_file_and_text
Feature: Radio with file and text field
  En tant que candidat à un marché public
  Je veux pouvoir répondre à une question avec un choix oui/non
  Et fournir optionnellement du texte ou des fichiers quand je choisis "oui"
  Afin de fournir des réponses flexibles aux questions

  Background:
    Given a public market with radio_with_file_and_text field exists
    And a candidate starts an application for this market radio

  Scenario: Submit with "No" selected is valid
    When I visit the radio field step
    And I select the "No" radio button
    And I click "Suivant"
    Then the radio form should be submitted successfully
    And the radio choice should be "no"

  Scenario: Submit with "Yes" and no additional data is valid
    When I visit the radio field step
    And I select the "Yes" radio button
    And I click "Suivant"
    Then the radio form should be submitted successfully
    And the radio choice should be "yes"

  Scenario: Submit with "Yes" and text only
    When I visit the radio field step
    And I select the "Yes" radio button
    And I fill in the text field with "Ma réponse détaillée"
    And I click "Suivant"
    Then the radio form should be submitted successfully
    And the radio response should contain text "Ma réponse détaillée"

  Scenario: Submit with "Yes" and file only
    When I visit the radio field step
    And I select the "Yes" radio button
    And I attach a file "test.pdf"
    And I click "Suivant"
    Then the radio form should be submitted successfully
    And the radio response should have 1 attached file

  Scenario: Submit with "Yes" and both text and file
    When I visit the radio field step
    And I select the "Yes" radio button
    And I fill in the text field with "Voir document joint"
    And I attach a file "document.pdf"
    And I click "Suivant"
    Then the radio form should be submitted successfully
    And the radio response should contain text "Voir document joint"
    And the radio response should have 1 attached file
