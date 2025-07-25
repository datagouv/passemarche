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
    And I should see "Étape 1 sur 2 : Documents requis"
    And I should see "Documents obligatoires"
    And I should see "Extrait Kbis"
    And I should see "Attestation fiscale"
    And I should see "Attestation sociale"
    And I should see "Assurance responsabilité civile"
    And I should see a "Précédent" button
    And I should see "Continuer vers les documents optionnels"
    
    When I click on "Continuer vers les documents optionnels"
    Then I should be on the optional documents page
    And I should see "Étape 2 sur 2 : Documents optionnels"
    And I should see "Sélectionnez les documents supplémentaires"
    And I should see "Références clients"
    And I should see "Bilans comptables"
    And I should see "Certifications qualité"
    And I should see "Moyens techniques"
    And I should see a "Précédent" button
    And I should see a button "Autoriser la candidature via"
    
    When I click on "Autoriser la candidature via"
    Then I should be on the summary page
    And I should see "Résumé de la configuration"
    And I should see "Documents obligatoires"
    And I should see "Documents optionnels"
    And I should see "Aucun document optionnel sélectionné"
    And I should see "Configuration terminée"
    And I should see a button "Finaliser la configuration"

  Scenario: Navigation arrière avec les boutons Précédent
    Given I am on the summary page for my public market
    When I go back to optional documents page
    Then I should be on the optional documents page
    And I should see "Étape 2 sur 2 : Documents optionnels"
    
    When I click on "Précédent"
    Then I should be on the required documents page
    And I should see "Étape 1 sur 2 : Documents requis"
    
    When I click on "Précédent"
    Then I should be on the configure page
    And I should see "Bienvenue,"

  Scenario: Vérification de la cohérence des informations du marché à travers les étapes
    When I visit the configure page for my public market
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "supplies"
    
    When I navigate to required documents page
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    
    When I navigate to optional documents page
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    
    When I navigate to summary page
    Then I should see "Fourniture de matériel informatique"
    And I should see "Lot 1 - Ordinateurs portables"
    And I should see "supplies"

  Scenario: Stepper indique correctement l'étape courante
    When I visit the required documents page for my public market
    Then I should see "Étape 1 sur 2 : Documents requis"
    And the stepper should indicate step 1 as current
    
    When I navigate to optional documents page
    Then I should see "Étape 2 sur 2 : Documents optionnels"
    And the stepper should indicate step 2 as current

  Scenario: Navigation directe vers différentes étapes
    When I visit the configure page for my public market
    Then I should be on the configure page
    
    When I visit the required documents page for my public market
    Then I should be on the required documents page
    And I should see "Documents obligatoires"
    
    When I visit the optional documents page for my public market
    Then I should be on the optional documents page
    And I should see "Documents optionnels"
    
    When I visit the summary page for my public market
    Then I should be on the summary page
    And I should see "Résumé de la configuration"