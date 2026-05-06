# frozen_string_literal: true
@candidate_webhook_sync
Feature: Synchronisation webhook candidat
  En tant que candidat
  Je veux voir l'état de synchronisation de ma candidature avec la plateforme éditeur
  Afin de savoir si elle a bien été transmise

  Background:
    Given un éditeur avec une URL webhook exists
    And une candidature associée à cet éditeur exists

  Scenario: Page en attente de synchronisation
    Given la candidature est en cours de synchronisation
    When je visite la page de statut de synchronisation candidat
    Then je vois "Synchronisation en cours"

  Scenario: Page de succès après synchronisation
    Given la candidature a été synchronisée avec succès
    When je visite la page de statut de synchronisation candidat
    Then je vois "Votre candidature a été transmise !"
    And je vois un lien pour retourner sur l'éditeur

  Scenario: Page d'erreur en cas d'échec de synchronisation
    Given la candidature a échoué à se synchroniser
    When je visite la page de statut de synchronisation candidat
    Then je vois "Erreur inattendue"
    And je vois un bouton "Retenter de transmettre ma candidature"
    And je vois un lien "Contactez-nous"

  Scenario: Réessai de synchronisation après un échec
    Given la candidature a échoué à se synchroniser
    And le webhook de l'éditeur répond avec succès
    When je visite la page de statut de synchronisation candidat
    And je clique sur "Retenter de transmettre ma candidature"
    Then je vois "Votre candidature a été transmise !"
