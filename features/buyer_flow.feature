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
      | market_name | Fourniture de matériel informatique |
      | lot_name    | Lot 1 - Ordinateurs portables       |
      | deadline    | 2025-12-31T23:59:59Z                |
      | market_type | supplies                            |

  Scenario: Navigation complète du flux acheteur - aller simple
    When I visit the configure page for my public market
    Then I should see "Bienvenue,"
    And I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "Cochez cette case uniquement si votre marché concerne la défense ou la sécurité"
    
    When I click on "Débuter l'activation de"
    Then I should be on the required documents page
    And I should see "Vérification des informations obligatoires"
    And I should see "Les documents et informations obligatoires"
    And I should see "Certificat de naissance de licorne"
    And I should see "Déclaration allergie aux pizzas"
    And I should see "Niveau d'addiction au café"
    And I should see a "Précédent" button
    And I should see "Continuer vers les champs supplémentaires"
    
    When I click on "Continuer vers les champs supplémentaires"
    Then I should be on the optional documents page
    And I should see "Sélection des informations complémentaires"
    And I should see "Les documents et informations complémentaires"
    And I should see "Permis de pilotage de fusée"
    And I should see "Certificat de furtivité ninja"
    And I should see "Permis de dressage de dragons"
    And I should see a "Précédent" button
    And I should see a button "Autoriser la candidature via"
    
    When I click on "Autoriser la candidature via"
    Then I should be on the summary page
    And I should see "Synthèse de ma candidature"
    And I should see "Informations du marché"
    And I should see "Identité de la licorne (test)"
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
    Then I should be on the configure page
    And I should see "Bienvenue,"

  Scenario: Vérification de la cohérence des informations du marché à travers les étapes
    When I visit the configure page for my public market
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "supplies"
    
    When I navigate to required documents page
    Then I should be on the required documents page
    
    When I navigate to optional documents page
    Then I should be on the optional documents page
    
    When I navigate to summary page
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "supplies"

  Scenario: Stepper indique correctement l'étape courante
    When I visit the required documents page for my public market
    Then I should see "Vérification des informations obligatoires"
    And the stepper should indicate step 1 as current
    
    When I navigate to optional documents page
    Then I should see "Sélection des informations complémentaires"
    And the stepper should indicate step 2 as current

  Scenario: Navigation directe vers différentes étapes
    When I visit the configure page for my public market
    Then I should be on the configure page
    
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
    Given I visit the configure page for my public market
    When I check the "defense" checkbox
    And I click on "Débuter l'activation de"
    Then the public market should be marked as defense
    And I should be on the required documents page

  Scenario: Ne pas marquer un marché comme défense en laissant la case décochée
    Given I visit the configure page for my public market
    When I click on "Débuter l'activation de"
    Then the public market should not be marked as defense
    And I should be on the required documents page

  Scenario: Marché avec défense pré-configuré par l'éditeur
    When I create a defense public market with the following details:
      | market_name | Fourniture de matériel militaire |
      | deadline    | 2025-12-31T23:59:59Z            |
      | market_type | supplies                        |
      | defense     | true                            |
    And I visit the configure page for my public market
    Then the defense checkbox should be disabled and checked
    And I should see "Cette désignation a été définie par"

  Scenario: Sélection de documents supplémentaires avec question oui/non
    When I visit the optional documents page for my public market
    Then I should see "Je veux demander des informations et documents complémentaires au candidat"
    And I should see "Oui"
    And I should see "Non"
