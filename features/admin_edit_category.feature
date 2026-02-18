# frozen_string_literal: true

@admin_edit_category
Feature: Admin - Modifier une categorie
  En tant qu'administrateur Passe Marche
  Je veux modifier les libelles d'une categorie
  Afin d'adapter la terminologie affichee a chaque profil

  Background:
    Given I am logged in as an admin user
    And the following categories with labels exist:
      | key                 | buyer_label             | candidate_label                     |
      | identite_entreprise | Identite de l'entreprise | Informations de votre entreprise   |

  Scenario: CA-1 - Edit modal opens with pre-filled labels
    When I click "Modifier" for category "identite_entreprise"
    Then I should see the edit category form
    And the buyer label field for category should contain "Identite de l'entreprise"
    And the candidate label field for category should contain "Informations de votre entreprise"

  Scenario: CA-2 - Modify buyer label only
    When I submit the edit form for category "identite_entreprise" with:
      | buyer_label     | Nouveau titre acheteur                |
      | candidate_label | Informations de votre entreprise      |
    Then the category "identite_entreprise" buyer label should be "Nouveau titre acheteur"
    And the category "identite_entreprise" candidate label should be "Informations de votre entreprise"

  Scenario: CA-3 - Modify candidate label only
    When I submit the edit form for category "identite_entreprise" with:
      | buyer_label     | Identite de l'entreprise             |
      | candidate_label | Nouveau titre candidat               |
    Then the category "identite_entreprise" candidate label should be "Nouveau titre candidat"
    And the category "identite_entreprise" buyer label should be "Identite de l'entreprise"

  Scenario: CA-4 - Validation error on blank label
    When I submit the edit form for category "identite_entreprise" with:
      | buyer_label     |                                     |
      | candidate_label | Informations de votre entreprise    |
    Then I should see a validation error

  Scenario: CA-5 - Update both labels simultaneously
    When I submit the edit form for category "identite_entreprise" with:
      | buyer_label     | Nouveau acheteur   |
      | candidate_label | Nouveau candidat   |
    Then the category "identite_entreprise" buyer label should be "Nouveau acheteur"
    And the category "identite_entreprise" candidate label should be "Nouveau candidat"
