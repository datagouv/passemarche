# frozen_string_literal: true
@candidate_api_data_recovery_status
Feature: Page de récupération des données API candidat
  En tant que candidat
  Je veux voir l'état de récupération de mes documents et informations
  Afin de suivre l'avancement du pré-remplissage de mon dossier

  Background:
    Given un marché avec des attributs API exists
    And une candidature pour ce marché exists

  Scenario: Affichage de la page avec les blocs en cours de récupération
    Given les APIs sont en cours de récupération
    When je visite la page de récupération des données API
    Then je vois "Nous pré-remplissons votre dossier de candidature"
    And je vois "Nous récupérons vos documents et informations"
    And je vois le bloc "Identité de l'entreprise"
    And le bouton "Continuer" est désactivé

  Scenario: Tous les blocs sont récupérés avec succès
    Given toutes les APIs ont été récupérées avec succès
    When je visite la page de récupération des données API
    Then je vois "L'ensemble des informations et documents ont été récupérés"
    And le bouton "Continuer" est activé

  Scenario: Certains blocs ont échoué
    Given certaines APIs ont échoué
    When je visite la page de récupération des données API
    Then je vois "Certaines informations ou documents n'ont pas pu être récupérés automatiquement"
    And le bouton "Continuer" est activé
