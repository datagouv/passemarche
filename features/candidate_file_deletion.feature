# frozen_string_literal: true

@javascript @candidate_file_deletion @wip
Feature: Candidate can delete uploaded files
  En tant que candidat remplissant une candidature
  Je veux pouvoir supprimer les fichiers que j'ai téléversés
  Afin de corriger des erreurs ou de changer d'avis

  Background:
    Given a public market with file upload fields exists
    And a candidate starts a new application for file deletion testing

  Scenario: Delete file immediately after upload (before form submission)
    When I visit the file upload step
    And I upload a test file "test-document.pdf"
    Then I should see "test-document.pdf" in the uploaded files list
    When I click the delete button for "test-document.pdf"
    And I confirm the deletion
    Then "test-document.pdf" should be removed from the files list
    And the blob should be deleted from storage

  Scenario: Delete file after form submission
    When I visit the file upload step
    And I upload a test file "test-document.pdf"
    Then I should see "test-document.pdf" in the uploaded files list
    When I submit the file upload form
    Then the form should be saved successfully
    When I return to the file upload step
    Then I should see "test-document.pdf" in the uploaded files list
    When I click the delete button for "test-document.pdf"
    And I confirm the deletion
    Then "test-document.pdf" should be removed from the files list
    And the attachment should be deleted from storage
