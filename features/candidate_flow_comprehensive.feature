# frozen_string_literal: true

@candidate_flow_comprehensive
Feature: Comprehensive Candidate Application Flow
  En tant que candidat à un marché public
  Je veux pouvoir soumettre ma candidature avec tous types de champs
  Afin de m'assurer que le processus fonctionne correctement avec STI et nested attributes

  Background:
    Given a comprehensive public market with all input types exists
    And a candidate starts a comprehensive application

  Scenario: Complete application flow with all input types
    When I visit the company identification step
    Then I should see the SIRET input field
    When I fill in the SIRET with "73282932000074"
    And I click "Suivant"

    Then I should be on the "identite_entreprise" step
    And I should see all required identity fields
    When I fill in all identity fields with valid data
    And I click "Suivant"

    Then I should be on the "exclusion_criteria" step
    And I should see checkbox fields
    When I check the required exclusion checkboxes
    And I click "Suivant"

    Then I should be on the "economic_capacities" step
    And I should see textarea fields
    When I fill in the economic capacity information
    And I click "Suivant"

    Then I should be on the "technical_capacities" step
    And I should see file upload fields
    When I upload required documents
    And I click "Suivant"

    Then I should be on the "summary" step
    And I should see a summary of all my responses
    When I click "Transmettre ma candidature"
    Then my application should be submitted successfully

  Scenario: Verify hidden type fields are present in all forms
    When I visit the "identite_entreprise" step
    Then each form field should have a type hidden field with correct STI class

    When I visit the "exclusion_criteria" step
    Then each checkbox field should have type "Checkbox"

    When I visit the "economic_capacities" step
    Then each textarea field should have type "Textarea"

    When I visit the "technical_capacities" step
    Then each file upload field should have type "FileUpload"

  Scenario: Test nested attributes submission and STI instantiation
    When I visit the "identite_entreprise" step
    And I fill in all identity fields with valid data
    And I submit the form
    Then all responses should be created with correct STI types
    And the email response should be of class "MarketAttributeResponse::EmailInput"
    And the phone response should be of class "MarketAttributeResponse::PhoneInput"
    And the text response should be of class "MarketAttributeResponse::TextInput"

  Scenario: Test form validation errors display correctly
    When I visit the "identite_entreprise" step
    And I fill in invalid data:
      | field | value |
      | email | invalid-email |
      | phone | 123 |
      | required_text | |
    And I submit the form
    Then I should see validation errors for:
      | field | error |
      | email | format invalide |
      | phone | format invalide |
      | required_text | requis |
    And the form should not be submitted

  Scenario: Test data persistence across steps
    When I visit the "identite_entreprise" step
    And I fill in:
      | field | value |
      | email | test@example.com |
      | phone | 01 23 45 67 89 |
      | text  | Test Company |
    And I click "Suivant"
    And I go back to "identite_entreprise" step
    Then the fields should contain the previously entered values:
      | field | expected_value |
      | email | test@example.com |
      | phone | 01 23 45 67 89 |
      | text  | Test Company |

  Scenario: Test checkbox with document functionality
    Given a market with checkbox_with_document fields exists
    When I visit the checkbox with document step
    Then I should see a checkbox and file upload combined
    When I check the checkbox
    And I upload a document
    And I submit the form
    Then the response should be of type "CheckboxWithDocument"
    And it should have both checked status and attached file


  Scenario: Test application completion workflow
    Given a comprehensive public market with all input types exists
    And a candidate starts a comprehensive application
    And I have filled all required fields across all steps
    When I complete the application on summary step
    Then the application status should be "completed"
    And I should be redirected to the success page
    And an attestation PDF should be generated
    And a documents package should be created

  Scenario: File upload with validation failure recovery
    When I visit the "technical_capacities" step
    Then I should see file upload fields
    When I upload a valid document "test_document.pdf"
    And I leave other required fields empty on the page
    And I click "Suivant"
    Then I should see validation errors
    And I should see "test_document.pdf (en cours de téléchargement)" in the uploaded files
    And the document should not have a download link
    When I fill in all required fields correctly
    And I click "Suivant"
    Then I should progress to the next step
    When I go back to "technical_capacities" step
    Then I should see "test_document.pdf" with a download link

  Scenario: Multiple file uploads and persistence
    When I visit the "technical_capacities" step
    And I upload multiple valid documents:
      | filename          | content_type     |
      | certificate.pdf   | application/pdf  |
      | reference.jpg     | image/jpeg       |
    And I click "Suivant"
    Then I should progress to the next step
    When I go back to "technical_capacities" step
    Then I should see all uploaded documents:
      | filename          |
      | certificate.pdf   |
      | reference.jpg     |
    And each document should have a download link

  Scenario: File upload validation errors
    When I visit the "technical_capacities" step
    And I attempt to upload an invalid file "document.txt"
    And I click "Suivant"
    Then I should see a file format validation error
    And I should remain on the "technical_capacities" step
    When I upload a valid document "valid_doc.pdf"
    And I click "Suivant"
    Then I should progress to the next step

  Scenario: File upload display states
    When I visit the "technical_capacities" step
    Then I should see "Aucun fichier téléchargé" message
    When I upload a valid document "new_file.pdf"
    But validation fails for other reasons
    And I click "Suivant"
    Then I should see "new_file.pdf (en cours de téléchargement)"
    And the file should not have a download link
    When I fix the validation issues and submit
    Then I should see "new_file.pdf" with a download link
    And I should not see "(en cours de téléchargement)" text