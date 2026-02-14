# frozen_string_literal: true

@admin_edit_subcategory
Feature: Admin - Modifier une sous-catégorie
  En tant qu'administrateur Passe Marché
  Je veux modifier l'intitulé et la catégorie parente d'une sous-catégorie
  Afin d'adapter la terminologie pour chaque profil d'utilisateur

  Background:
    Given I am logged in as an admin user
    And the following categories exist:
      | key                 | buyer_label               | candidate_label                                     | position |
      | identite_entreprise | Identité de l'entreprise  | Les informations du marché et de votre entreprise   | 0        |
      | motifs_exclusion    | Les motifs d'exclusion    | Les justificatifs relatifs aux motifs d'exclusion   | 1        |
    And the following subcategories exist:
      | key            | buyer_label                    | candidate_label                  | category_key        | position |
      | identification | Identification de l'entreprise | Informations de votre entreprise | identite_entreprise | 0        |

  Scenario: Edit modal displays pre-filled fields
    When I visit the categories page
    And I click "Modifier" for subcategory "identification"
    Then I should see the edit subcategory form
    And the buyer label field should contain "Identification de l'entreprise"
    And the candidate label field should contain "Informations de votre entreprise"

  Scenario: Successfully update buyer label only
    When I submit the edit form for subcategory "identification" with:
      | buyer_label     | Nouveau libellé acheteur         |
      | candidate_label | Informations de votre entreprise |
      | category_key    | identite_entreprise              |
    Then the subcategory "identification" buyer label should be "Nouveau libellé acheteur"
    And the subcategory "identification" candidate label should be "Informations de votre entreprise"

  Scenario: Successfully update candidate label only
    When I submit the edit form for subcategory "identification" with:
      | buyer_label     | Identification de l'entreprise   |
      | candidate_label | Nouveau libellé candidat         |
      | category_key    | identite_entreprise              |
    Then the subcategory "identification" buyer label should be "Identification de l'entreprise"
    And the subcategory "identification" candidate label should be "Nouveau libellé candidat"

  Scenario: Successfully change parent category
    When I submit the edit form for subcategory "identification" with:
      | buyer_label     | Identification      |
      | candidate_label | Informations        |
      | category_key    | motifs_exclusion    |
    Then the subcategory "identification" should belong to category "motifs_exclusion"

  Scenario: Validation error when buyer label is blank
    When I submit the edit form for subcategory "identification" with:
      | buyer_label     |                                  |
      | candidate_label | Informations de votre entreprise |
      | category_key    | identite_entreprise              |
    Then I should see a validation error
    And the subcategory "identification" buyer label should be "Identification de l'entreprise"

  Scenario: Validation error when candidate label is blank
    When I submit the edit form for subcategory "identification" with:
      | buyer_label     | Identification de l'entreprise |
      | candidate_label |                                |
      | category_key    | identite_entreprise            |
    Then I should see a validation error
    And the subcategory "identification" candidate label should be "Informations de votre entreprise"
