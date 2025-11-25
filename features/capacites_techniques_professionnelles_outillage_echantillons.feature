# frozen_string_literal: true

@capacites_techniques_professionnelles_outillage
Feature: Capacités techniques et professionnelles - Illustration des réalisations avec échantillons
  En tant que candidat à un marché public
  Je veux pouvoir fournir des échantillons, photographies ou descriptions de mes fournitures
  Afin d'illustrer mes réalisations et démontrer la qualité de mes fournitures

  Background:
    Given a public market with capacites_techniques_professionnelles_outillage_echantillons field exists
    And a candidate starts an application for this echantillons market

  Scenario: Display of empty form with add échantillon functionality
    When I visit the echantillons step
    Then I should see the title "Illustration des réalisations : échantillons, photographie ou description des fournitures"
    And I should see the echantillons "Ajouter un échantillon" button

  Scenario: Form has dynamic échantillon adding infrastructure
    When I visit the echantillons step
    Then the echantillons page should have a nested-form controller for dynamic fields
    And the echantillons page should have a button to add echantillons dynamically

  Scenario: Successful form submission with single échantillon
    Given I have submitted single echantillon data:
      | description                                                              |
      | Échantillon de mobilier urbain conforme aux normes PMR, acier inoxydable |
    Then the echantillon data should be saved correctly

  Scenario: Successful form submission with multiple échantillons
    Given I have submitted echantillons data with multiple items:
      | description                                    |
      | Échantillon de mobilier urbain acier inoxydable |
      | Prototype de signalétique conforme PMR          |
    Then both echantillons data should be saved correctly

  Scenario: Removing an échantillon from the form
    Given I have submitted single echantillon data:
      | description                          |
      | Prototype de signalétique PMR        |
    Then only echantillon 2 data should be saved

  Scenario: Échantillon with only file attachment is valid (description optional)
    When I visit the echantillons step
    And I submit échantillon with only file attachment
    Then the échantillon form should be submitted successfully

  Scenario: Display of submitted data in summary
    Given I have submitted echantillons data with multiple items:
      | description                                    |
      | Échantillon de mobilier urbain acier inoxydable |
      | Prototype de signalétique conforme PMR          |
    When I visit the summary step
    Then I should see the echantillons data displayed:
      | echantillon   | description                                    |
      | Échantillon 1 | Échantillon de mobilier urbain acier inoxydable |
      | Échantillon 2 | Prototype de signalétique conforme PMR          |

  Scenario: STI class verification
    When I visit the echantillons step
    Then the form should have a hidden type field with value "CapacitesTechniquesProfessionnellesOutillageEchantillons"

  Scenario: Data persistence across navigation
    Given I have submitted echantillon data:
      | description                                  |
      | Échantillon de mobilier urbain PMR standard  |
    When I navigate back to the echantillons step
    Then the saved echantillon data should be displayed in the form

  Scenario: Empty state handling in summary
    When I visit the echantillons step
    And I click "Suivant" without adding any échantillons
    And I visit the summary step
    Then I should see "Aucun échantillon renseigné" in the echantillons summary

  Scenario: File upload for échantillon
    Given I have an échantillon with fichiers:
      | description          | fichiers    |
      | Prototype mobilier   | test.pdf    |
    Then the fichiers should be attached to the échantillon
    When I visit the summary step
    Then I should see the fichiers in the summary

  Scenario: Multiple files upload for single échantillon
    Given I have an échantillon with multiple fichiers:
      | description          | fichiers                |
      | Prototype complet    | photo1.jpg,photo2.jpg   |
    Then all fichiers should be attached to the échantillon
    When I visit the summary step
    Then I should see all fichiers in the summary
