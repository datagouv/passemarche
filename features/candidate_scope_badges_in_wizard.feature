@candidate_scope_badges
Feature: Scope badges in candidate wizard for multi-type markets
  En tant que candidat à un marché multi-types
  Je veux voir les badges de type sur chaque champ du formulaire
  Afin de savoir à quel type de lot chaque information est rattachée

  Background:
    Given a multi-type public market with scope attributes exists
    And a candidate starts an application with one lot of each type

  Scenario: Les badges de type apparaissent sur les champs spécifiques à un type
    When the candidate visits the wizard step for scope attributes
    Then they should see a scope badge for "works" on the works-specific field
    And they should see a scope badge for "services" on the services-specific field

  Scenario: Le badge commun apparaît sur les champs partagés entre types
    When the candidate visits the wizard step for scope attributes
    Then they should see a commun scope badge on the shared field

  Scenario: Aucun badge n'apparaît quand le candidat ne sélectionne qu'un seul type de lot
    Given a candidate starts an application with only a works lot
    When the candidate visits the wizard step for scope attributes
    Then they should not see any scope badges
