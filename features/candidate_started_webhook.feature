# frozen_string_literal: true

@candidate_started_webhook
Feature: Notification « candidature en cours » à la plateforme
  En tant que plateforme de marchés publics
  Je veux être prévenue quand un candidat commence à remplir sa candidature
  Afin d'afficher qu'une candidature est en cours

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And l'éditeur reçoit les webhooks sur "https://editor.example.com/webhook"
    And un marché public ouvert existe avec des attributs

  Scenario: La plateforme est prévenue quand le candidat arrive sur les informations du marché (CA-1)
    Given le profil acheteur crée une candidature pour le même SIRET
    When le candidat arrive sur l'étape des informations du marché
    Then la plateforme a reçu 1 fois le statut « en cours » de la candidature

  Scenario: La plateforme n'est prévenue qu'une fois tant que la candidature reste en cours
    Given le profil acheteur crée une candidature pour le même SIRET
    When le candidat arrive sur l'étape des informations du marché
    And le candidat valide l'étape des informations du marché
    And le candidat arrive sur l'étape des informations du marché
    Then la plateforme a reçu 1 fois le statut « en cours » de la candidature

  Scenario: La plateforme est de nouveau prévenue après une recandidature (CA-2)
    Given une candidature démarrée puis transmise existe
    When le profil acheteur crée une candidature pour le même SIRET
    And le candidat arrive sur l'étape des informations du marché
    Then la plateforme a reçu 1 fois le statut « en cours » de la candidature
