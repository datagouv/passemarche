# frozen_string_literal: true
@buyer_flow
Feature: Buyer Configuration Flow
  En tant qu'acheteur public
  Je veux pouvoir configurer mon marché étape par étape
  Afin de paramétrer les documents requis pour les candidatures

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And I create a public market with the following details:
      | name | Fourniture de matériel informatique |
      | lot_name    | Lot 1 - Ordinateurs portables       |
      | deadline    | 2025-12-31T23:59:59Z                |
      | market_types | supplies                            |

  Scenario: Navigation complète du flux acheteur - aller simple
    When I visit the setup page for my public market
    Then I should see "Bienvenue,"
    And I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "Cochez cette case uniquement si votre marché concerne la défense ou la sécurité"
    
    When I click on "Débuter l'activation de"
    Then I should be on the required documents page
    And I should see "Vérification des informations obligatoires"
    And I should see "Les documents et informations obligatoires"
    And I should see "Identité de l'entreprise"
    And I should see "Nom de l'entreprise"
    And I should see "Condamnation pénale"
    And I should see a "Précédent" button
    And I should see a button "Suivant"
    
    When I click on "Suivant"
    Then I should be on the optional documents page
    And I should see "Sélection des informations complémentaires"
    And I should see "Les documents et informations complémentaires"
    And I should see "Chiffre d'affaires annuel"
    And I should see "Rupture antérieure de contrat"
    And I should see "Influence indue"
    And I should see a "Précédent" button
    And I should see a button "Suivant"
    
    When I click on "Suivant"
    Then I should be on the summary page
    And I should see "Synthèse de ma candidature"
    And I should see "Informations du marché"
    And I should see "Identité de l'entreprise"
    And I should see a disabled button "Finaliser la configuration"

  Scenario: Navigation arrière avec les boutons Précédent
    Given I am on the summary page for my public market
    When I go back to optional documents page
    Then I should be on the optional documents page
    And I should see "Sélection des informations complémentaires"
    
    When I click on "Précédent"
    Then I should be on the required documents page
    And I should see "Vérification des informations obligatoires"
    
    When I click on "Précédent"
    Then I should be on the setup page
    And I should see "Bienvenue,"

  Scenario: Vérification de la cohérence des informations du marché à travers les étapes
    When I visit the setup page for my public market
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "Fournitures"
    
    When I navigate to required documents page
    Then I should be on the required documents page
    
    When I navigate to optional documents page
    Then I should be on the optional documents page
    
    When I navigate to summary page
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "Fournitures"

  Scenario: Stepper indique correctement l'étape courante
    When I visit the required documents page for my public market
    Then I should see "Vérification des informations obligatoires"
    And the stepper should indicate step 1 as current
    
    When I navigate to optional documents page
    Then I should see "Sélection des informations complémentaires"
    And the stepper should indicate step 2 as current

  Scenario: Navigation directe vers différentes étapes
    When I visit the setup page for my public market
    Then I should be on the setup page
    
    When I visit the required documents page for my public market
    Then I should be on the required documents page
    And I should see "Les documents et informations obligatoires"
    
    When I visit the optional documents page for my public market
    Then I should be on the optional documents page
    And I should see "Les documents et informations complémentaires"
    
    When I visit the summary page for my public market
    Then I should be on the summary page
    And I should see "Synthèse de ma candidature"

  Scenario: Marquer un marché comme défense en cochant la case
    Given I visit the setup page for my public market
    When I check the "defense_industry" checkbox
    And I click on "Débuter l'activation de"
    Then the public market should be marked as defense_industry
    And I should be on the required documents page

  Scenario: Ne pas marquer un marché comme défense en laissant la case décochée
    Given I visit the setup page for my public market
    When I click on "Débuter l'activation de"
    Then the public market should not be marked as defense_industry
    And I should be on the required documents page

  Scenario: Marché avec défense pré-configuré par l'éditeur
    When I create a defense_industry public market with the following details:
      | name | Fourniture de matériel militaire |
      | deadline    | 2025-12-31T23:59:59Z            |
      | market_types | supplies                        |
      | defense_industry     | true                            |
    And I visit the setup page for my public market
    Then the defense_industry checkbox should be disabled and checked
    And I should see "Cette désignation a été définie par"

  Scenario: Sélection de documents supplémentaires avec question oui/non
    When I visit the optional documents page for my public market
    Then I should see "Je veux demander des informations et documents complémentaires au candidat"
    And I should see "Oui"
    And I should see "Non"

  Scenario: Les attributs obligatoires sont automatiquement ajoutés à l'étape required_fields
    When I visit the required documents page for my public market
    And I click on "Suivant"
    Then the public market should have all required attributes from its market types
    And I should be on the optional documents page
