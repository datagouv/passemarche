@admin_authorization
Feature: Admin role-based access control
  En tant qu'administrateur Passe Marche
  Je veux que les droits soient geres par role
  Afin de proteger les actions de modification

  Scenario: Lecteur can view editors list but not modification actions
    Given I am logged in as a lecteur user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editors page
    Then I should see "Editor 1" on the page
    And I should not see the add editor button

  Scenario: Admin can see all modification actions
    Given I am logged in as an admin user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editors page
    Then I should see the add editor button

  Scenario: Lecteur cannot access editor creation page
    Given I am logged in as a lecteur user
    When I try to access the new editor page
    Then I should be redirected to the admin root
    And I should see a permission denied message

  Scenario: Lecteur can view editor details but not edit/delete actions
    Given I am logged in as a lecteur user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editor page for "Editor 1"
    Then I should see "Editor 1" on the page
    And I should not see edit and delete buttons

  Scenario: Admin can see edit and delete actions on editor details
    Given I am logged in as an admin user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editor page for "Editor 1"
    Then I should see edit and delete buttons

  Scenario: Lecteur can access dashboard
    Given I am logged in as a lecteur user
    When I visit the admin dashboard
    Then I should see "Suivi d" on the page
