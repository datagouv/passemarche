# frozen_string_literal: true

@admin_dashboard
Feature: Admin Activity Dashboard
  En tant qu'administrateur Passe Marche
  Je veux consulter un tableau de bord de suivi d'activite
  Afin de suivre l'adoption du produit et l'activite globale

  Background:
    Given I am logged in as an admin user

  Scenario: Viewing the global activity dashboard
    Given the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
      | Editor 2 | false      | true   |
    And "Editor 1" has 2 public markets
    And "Editor 1" has 1 completed market application
    When I visit the admin dashboard
    Then I should see "Suivi d" on the page
    And I should see the statistic "diteurs configur" with value "2"
    And I should see the statistic "diteurs actifs" with value "1"
    And I should see the statistic "s cr" with value "2"

  Scenario: Filtering dashboard by editor via URL
    Given the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
      | Editor 2 | true       | true   |
    And "Editor 1" has 3 public markets
    And "Editor 2" has 1 public market
    When I visit the admin dashboard filtered by "Editor 1"
    Then I should see "Editor 1" on the page
    And I should see the statistic "s cr" with value "3"

  Scenario: Accessing filtered dashboard from editor page
    Given the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editor page for "Editor 1"
    And I click on the admin link "Voir les statistiques"
    Then I should see "Editor 1" on the page
    And I should see "Suivi d" on the page

  Scenario: Exporting dashboard statistics as CSV
    Given the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin dashboard
    And I click on the admin link "Exporter (CSV)"
    Then I should receive a CSV file named "statistiques-passe-marche-global"
