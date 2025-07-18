# frozen_string_literal: true

Feature: Fast Track Home Page
  As a user visiting the Fast Track application
  I want to see the home page
  So that I can confirm the application is working

  Scenario: User visits the home page
    Given I am on the home page
    Then I should see "Voie Rapide"
    And I should see "La plateforme de candidature simplifiée aux marchés publics"
    And I should see "Facilitez vos démarches administratives"

  Scenario: User sees DSFR French government design
    Given I am on the home page
    Then I should see "République"
    And I should see "Française"
    And I should see "Simplifiez vos candidatures aux marchés publics"
    And I should see "Bienvenue sur"
    And I should see "la plateforme qui simplifie"

  Scenario: User sees the application features and workflow
    Given I am on the home page
    Then I should see "Fonctionnalités principales"
    And I should see "Identification SIRET automatique"
    And I should see "Gestion documentaire intégrée"
    And I should see "Comment ça marche ?"
    And I should see "1. Identification"
    And I should see "2. Documents"
    And I should see "3. Candidature"