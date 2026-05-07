# frozen_string_literal: true
@buyer_webhook_sync
Feature: Synchronisation webhook acheteur
  En tant qu'acheteur public
  Je veux voir l'état de synchronisation de mon marché avec la plateforme éditeur
  Afin de savoir si la configuration a bien été transmise

  Background:
    Given un éditeur avec une URL webhook exists
    And un marché public associé à cet éditeur exists

  Scenario: Page en attente de synchronisation
    Given le marché est en cours de synchronisation
    When je visite la page de statut de synchronisation acheteur
    Then je vois "Synchronisation en cours"

  Scenario: Page de succès après synchronisation sans URL de retour acheteur configurée
    Given le marché a été synchronisé avec succès
    When je visite la page de statut de synchronisation acheteur
    Then je vois "Synchronisation réussie"
    And je vois l'identifiant du marché sur la page
    And je vois un lien de retour vers la page d'accueil

  Scenario: Page de succès après synchronisation avec URL de retour acheteur configurée
    Given l'éditeur a une URL de retour acheteur "https://editeur.example.com/marches"
    And le marché a été synchronisé avec succès
    When je visite la page de statut de synchronisation acheteur
    Then je vois "Synchronisation réussie"
    And je vois un lien de retour vers "https://editeur.example.com/marches"

  Scenario: Page d'erreur en cas d'échec de synchronisation
    Given le marché a échoué à se synchroniser
    When je visite la page de statut de synchronisation acheteur
    Then je vois "Erreur inattendue"
    And je vois un bouton "Transmettre le formulaire"
    And je vois un lien "Contactez-nous"

  Scenario: Réessai de synchronisation après un échec
    Given le marché a échoué à se synchroniser
    And le webhook de l'éditeur répond avec succès
    When je visite la page de statut de synchronisation acheteur
    And je clique sur "Transmettre le formulaire"
    Then je vois "Synchronisation réussie"
