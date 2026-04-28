# frozen_string_literal: true

@admin_audit_logs
Feature: Admin - Historique des modifications du socle de base
  En tant qu'administrateur Passe Marche
  Je veux consulter l'historique des modifications du socle de base
  Afin de tracer toutes les actions effectuees sur les champs

  Background:
    Given I am logged in as an admin user

  Scenario: Access history page from socle de base dropdown
    When I visit the socle de base page
    Then I should see the history link in the dropdown

  Scenario: View empty audit log page
    When I visit the audit logs page with no prior versions
    Then I should see "Historique des modifications"
    And I should see "Aucune modification enregistrée"

  Scenario: View audit log entries in a table
    Given audit log entries exist for market attribute changes
    When I visit the audit logs page
    Then I should see audit log entries in the table
    And I should see "Création" in the audit logs table

  Scenario: Filter audit logs by text search
    Given audit log entries exist for market attribute changes
    When I visit the audit logs page
    And I filter audit logs by text "identite"
    Then I should see filtered audit log results

  Scenario: Filter audit logs by date range
    Given audit log entries exist for market attribute changes
    When I visit the audit logs page
    And I filter audit logs by today's date range
    Then I should see filtered audit log results

  Scenario: View detail of a modification
    Given a modification audit log entry exists
    When I visit the audit logs page
    And I click "Voir le détail" for the first audit log entry
    Then I should see the modification details
    And I should see "Avant"
    And I should see "Après"

  Scenario: View detail of a creation
    Given audit log entries exist for market attribute changes
    When I visit the audit logs page
    And I click "Voir le détail" for the first audit log entry
    Then I should see the creation details
    And I should see "Contenu acheteur"

  Scenario: Non-authenticated user cannot access history
    Given I am not logged in as admin
    When I try to visit the audit logs page
    Then I should be redirected to the admin login page
