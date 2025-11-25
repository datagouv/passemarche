# frozen_string_literal: true

@document_display_naming
Feature: Document Display with System Naming
  En tant que candidat ou acheteur
  Je veux voir les fichiers avec le bon format de nommage
  Afin de pouvoir faire le lien entre le nom original et le nom dans le package ZIP

  Background:
    Given a public market with file upload field exists
    And a candidate has started an application
    And I visit the documents step

  Scenario: Candidate sees original filename after upload
    When I upload a file "rapport_technique.pdf"
    And I click "Suivant"
    And I go back to "documents" step
    Then I should see "rapport_technique.pdf" in the uploaded files

  Scenario: Candidate sees system filename mapping on summary page
    When I upload a file "rapport_technique.pdf"
    And I complete all remaining steps to reach summary
    Then I should be on the "summary" step
    And I should see the original filename "rapport_technique.pdf"
    And I should see the system filename prefix "user_01_01"
    And I should see the arrow symbol between filenames

  Scenario: Multiple file uploads show sequential numbering on summary
    Given the file upload field accepts multiple files
    When I upload multiple files:
      | filename             |
      | document_a.pdf       |
      | document_b.pdf       |
    And I complete all remaining steps to reach summary
    Then I should be on the "summary" step
    And I should see "document_a.pdf" with system prefix "user_01_01"
    And I should see "document_b.pdf" with system prefix "user_01_02"
