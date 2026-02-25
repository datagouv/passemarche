# frozen_string_literal: true

@admin_authorization
Feature: Admin role-based access control
  En tant qu'administrateur Passe Marche
  Je veux que les droits soient geres par role
  Afin de proteger les actions de modification

  # --- Editors ---

  Scenario: Lecteur sees disabled add editor button
    Given I am logged in as a lecteur user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editors page
    Then I should see "Editor 1" on the page
    And I should see a disabled add editor button

  Scenario: Admin sees enabled add editor button
    Given I am logged in as an admin user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editors page
    Then I should see an enabled add editor button

  Scenario: Lecteur cannot access editor creation page
    Given I am logged in as a lecteur user
    When I try to access the new editor page
    Then I should be redirected to the admin root
    And I should see a permission denied message

  Scenario: Lecteur sees disabled edit and delete buttons on editor details
    Given I am logged in as a lecteur user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editor page for "Editor 1"
    Then I should see "Editor 1" on the page
    And I should see disabled edit and delete buttons

  Scenario: Admin sees enabled edit and delete buttons on editor details
    Given I am logged in as an admin user
    And the following editors exist:
      | name     | authorized | active |
      | Editor 1 | true       | true   |
    When I visit the admin editor page for "Editor 1"
    Then I should see enabled edit and delete buttons

  Scenario: Lecteur can access dashboard
    Given I am logged in as a lecteur user
    When I visit the admin dashboard
    Then I should see "Suivi d" on the page

  # --- Socle de base ---

  Scenario: Lecteur sees disabled mutation buttons on socle de base index
    Given I am logged in as a lecteur user
    And the following market types exist:
      | code  |
      | works |
    And the following market attributes exist:
      | key        | category_key        | subcategory_key                    | mandatory | api_name | market_types |
      | test_field | identite_entreprise | identite_entreprise_identification | true      | Insee    | works        |
    When I visit the socle de base page
    Then I should see a disabled import button
    And I should see a disabled new field button
    And I should see a disabled archive button for the field

  Scenario: Lecteur cannot access socle de base creation page
    Given I am logged in as a lecteur user
    When I try to access the new socle de base page
    Then I should be redirected to the admin root
    And I should see a permission denied message

  Scenario: Lecteur sees disabled buttons on socle de base show page
    Given I am logged in as a lecteur user
    And the following market types exist:
      | code  |
      | works |
    And the following market attributes exist:
      | key        | category_key        | subcategory_key                    | mandatory | api_name | market_types |
      | test_field | identite_entreprise | identite_entreprise_identification | true      | Insee    | works        |
    When I visit the socle de base detail page for "test_field"
    Then I should see a disabled archive button
    And I should see a disabled edit button

  # --- Categories ---

  Scenario: Lecteur sees disabled create dropdown on categories page
    Given I am logged in as a lecteur user
    And the following categories exist:
      | key          | buyer_label  | candidate_label | position |
      | test_cat     | Test Cat     | Test Cat Cand   | 0        |
    And the following subcategories exist:
      | key      | buyer_label | candidate_label | category_key | position |
      | test_sub | Test Sub    | Test Sub Cand   | test_cat     | 0        |
    When I visit the categories page
    Then I should see a disabled create dropdown button
    And I should see disabled edit buttons for categories
    And I should see disabled edit buttons for subcategories

  Scenario: Lecteur cannot access category edit page
    Given I am logged in as a lecteur user
    And the following categories exist:
      | key      | buyer_label | candidate_label | position |
      | test_cat | Test Cat    | Test Cat Cand   | 0        |
    When I try to access the edit category page for "test_cat"
    Then I should be redirected to the admin root
    And I should see a permission denied message

  Scenario: Lecteur cannot access subcategory edit page
    Given I am logged in as a lecteur user
    And the following categories exist:
      | key      | buyer_label | candidate_label | position |
      | test_cat | Test Cat    | Test Cat Cand   | 0        |
    And the following subcategories exist:
      | key      | buyer_label | candidate_label | category_key | position |
      | test_sub | Test Sub    | Test Sub Cand   | test_cat     | 0        |
    When I try to access the edit subcategory page for "test_sub"
    Then I should be redirected to the admin root
    And I should see a permission denied message
