# frozen_string_literal: true

@buyer_configuration_summary_pdf
Feature: Synthèse PDF de la configuration acheteur
  En tant qu'acheteur
  Je veux disposer d'une synthèse au format PDF de la configuration de mon marché
  Afin de conserver une trace de la configuration et la partager via mon profil acheteur

  Background:
    Given an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And a "supplies" market type exists with mandatory fields
    And the editor webhook responds with success

  Scenario: CA-1 - Un PDF de synthèse est généré et téléchargeable à la transmission de la configuration
    Given a completed but non-published market exists for the current editor
    When I visit the summary page for the completed market
    And I submit the summary step
    Then a configuration summary PDF should be attached to the market
    And I should see the download configuration summary button

  Scenario: CA-3 - Une nouvelle synthèse PDF horodatée est générée à chaque nouvelle transmission
    Given a completed but non-published market exists for the current editor
    And a configuration summary PDF is already attached to the market
    When I visit the summary page for the completed market
    And I submit the summary step
    Then the configuration summary PDF should have been replaced

  Scenario: CA-4 - La synthèse est générée pour un marché multi-type avec des lots de types différents
    Given a completed but non-published market with multi-type lots exists for the current editor
    When I visit the summary page for the completed market
    And I submit the summary step
    Then a configuration summary PDF should be attached to the market
