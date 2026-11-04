# frozen_string_literal: true

@candidate_recandidate
Feature: Re-candidature candidat
  En tant que candidat
  Je veux pouvoir re-candidater avec le même SIRET à un marché encore ouvert
  Afin de corriger ou compléter ma candidature, ma nouvelle candidature remplaçant la précédente

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And un marché public ouvert existe avec des attributs

  Scenario: Re-candidature avec pré-remplissage des données manuelles (CA-1)
    Given une candidature complétée existe avec des données manuelles et API
    When le profil acheteur crée une candidature pour le même SIRET
    Then la réponse API est un succès
    And la candidature est remise à zéro
    And les données manuelles sont conservées
    And les données API sont supprimées

  Scenario: Les appels API sont relancés lors de la re-candidature (CA-2)
    Given une candidature complétée existe avec des données manuelles et API
    When le profil acheteur crée une candidature pour le même SIRET
    Then le statut de récupération API est réinitialisé

  Scenario: Re-candidature non resetée si date limite dépassée (CA-5)
    Given une candidature complétée existe avec des données manuelles et API
    And la date limite du marché est dépassée
    When le profil acheteur crée une candidature pour le même SIRET
    Then la réponse API est un succès
    And la candidature reste complétée
