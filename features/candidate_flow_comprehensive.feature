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
    And I click "Continuer"

    Then I should be on the "api_data_recovery_status" step
    And I should see API names list
    When all APIs complete successfully
    And I click "Continuer"

    Then I should be on the "market_information" step
    And I should see market information
    When I click "Suivant"

    # The actual order follows database ID creation order
    Then I should be on the "contact" step
    And I should see email and phone fields
    When I fill in contact fields with valid data
    And I click "Suivant"

    Then I should be on the "identification" step
    And I should see company name field
    When I fill in identification fields with valid data
    And I click "Suivant"

    Then I should be on the "declarations" step
    And I should see checkbox fields
    When I check the required exclusion checkboxes
    And I click "Suivant"

    Then I should be on the "description" step
    And I should see textarea fields
    When I fill in the economic capacity information
    And I click "Suivant"

    Then I should be on the "documents" step
    And I should see file upload fields
    When I upload required documents
    And I click "Suivant"

    Then I should be on the "attestations" step
    And I should see checkbox with document field
    When I handle optional checkbox with document
    And I click "Suivant"

    Then I should be on the "certifications" step
    When I handle optional checkbox with document
    And I click "Suivant"

    Then I should be on the "capacite_economique_financiere_chiffre_affaires" step
    When I fill in the turnover percentages
    And I click "Suivant"

    Then I should be on the "summary" step
    And I should see a summary of all my responses
    When I click "Transmettre ma candidature"
    Then my application should be submitted successfully

  Scenario: Verify hidden type fields are present in all forms
    When I visit the "contact" step
    Then each form field should have a type hidden field with correct STI class

    When I visit the "declarations" step
    Then each checkbox field should have type "Checkbox"

    When I visit the "description" step
    Then each textarea field should have type "Textarea"

    When I visit the "documents" step
    Then each file upload field should have type "FileUpload"

  Scenario: Test nested attributes submission and STI instantiation
    When I visit the "contact" step
    And I fill in contact fields with valid data
    And I submit the form
    When I visit the "identification" step
    And I fill in identification fields with valid data
    And I submit the form
    Then all responses should be created with correct STI types
    And the email response should be of class "MarketAttributeResponse::EmailInput"
    And the phone response should be of class "MarketAttributeResponse::PhoneInput"
    And the text response should be of class "MarketAttributeResponse::TextInput"

  Scenario: Comprehensive STI class verification for all input types
    When I visit the "contact" step
    And I fill in contact fields with valid data
    And I submit the form
    When I visit the "identification" step
    And I fill in identification fields with valid data
    And I submit the form
    When I visit the "declarations" step
    And I check the required exclusion checkboxes
    And I submit the form
    When I visit the "description" step
    And I fill in the economic capacity information
    And I submit the form
    When I visit the "documents" step
    And I upload required documents
    And I submit the form
    Then all responses should be created with correct STI types
    And the email response should be of class "MarketAttributeResponse::EmailInput"
    And the phone response should be of class "MarketAttributeResponse::PhoneInput"
    And the text response should be of class "MarketAttributeResponse::TextInput"
    And the checkbox response should be of class "MarketAttributeResponse::Checkbox"
    And the textarea response should be of class "MarketAttributeResponse::Textarea"
    And the file upload response should be of class "MarketAttributeResponse::FileUpload"

  Scenario: Test form validation errors display correctly for format errors
    When I visit the "contact" step
    And I fill in invalid data:
      | field | value |
      | email | invalid-email |
      | phone | 123 |
    And I submit the form
    Then I should see validation errors for:
      | field | error |
      | email | format invalide |
      | phone | format invalide |

  Scenario: Test data persistence across steps
    When I visit the "contact" step
    And I fill in:
      | field | value |
      | email | test@example.com |
      | phone | 01 23 45 67 89 |
    And I click "Suivant"
    And I go back to "contact" step
    Then the fields should contain the previously entered values:
      | field | expected_value |
      | email | test@example.com |
      | phone | 01 23 45 67 89 |

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

  Scenario: File upload is optional and can be skipped
    When I visit the "documents" step
    Then I should see file upload fields
    When I leave the required file upload empty
    And I click "Suivant"
    Then I should progress to the next step
    When I go back to "documents" step
    And I upload a valid document "test_document.pdf"
    And I click "Suivant"
    Then I should progress to the next step
    When I go back to "documents" step
    Then I should see "test_document.pdf" with a download link

  Scenario: Multiple file uploads and persistence
    When I visit the "documents" step
    And I upload multiple valid documents:
      | filename          | content_type     |
      | certificate.pdf   | application/pdf  |
      | reference.jpg     | image/jpeg       |
    And I click "Suivant"
    Then I should progress to the next step
    When I go back to "documents" step
    Then I should see all uploaded documents:
      | filename          |
      | certificate.pdf   |
      | reference.jpg     |
    And each document should have a download link

  Scenario: File upload validation errors
    When I visit the "documents" step
    And I attempt to upload an invalid file "document.txt"
    And I click "Suivant"
    Then I should see a file format validation error
    And I should remain on the "documents" step
    When I upload a valid document "valid_doc.pdf"
    And I click "Suivant"
    Then I should progress to the next step

  Scenario: File upload display states
    When I visit the "documents" step
    Then I should see "Aucun fichier téléchargé" message
    When I upload a valid document "new_file.pdf"
    And I click "Suivant"
    Then I should progress to the next step
    When I go back to "documents" step
    Then I should see "new_file.pdf" with a download link

  Scenario: Side menu highlights current step
    When I visit the "contact" step
    Then the current step should be highlighted in the side menu
