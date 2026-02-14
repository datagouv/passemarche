# frozen_string_literal: true

@admin_import_configuration
Feature: Admin - Importer une configuration
  En tant qu'administrateur Passe Marche
  Je veux importer une configuration CSV du socle de base
  Afin de deployer les parametrages entre environnements

  Background:
    Given I am logged in as an admin user

  Scenario: Import page displays import button in dropdown
    When I visit the socle de base page
    Then I should see the import action in the dropdown

  Scenario: Successful CSV import displays statistics
    When I import the test CSV file
    Then I should see the import success message

  Scenario: Import without file displays error message
    When I submit the import form without a file
    Then I should see the missing file error
