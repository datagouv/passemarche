# frozen_string_literal: true

Feature: Passe Marché Home Page
  As a user visiting the Passe Marché application
  I want to see the home page
  So that I can confirm the application is working

  Scenario: User visits the home page
    Given I am on the home page
    Then I should see "Passe Marché"
    And I should see "La plateforme de candidature simplifiée aux marchés publics"

  Scenario: User sees DSFR French government design
    Given I am on the home page
    Then I should see "République"
    And I should see "Française"

  Scenario: User sees the application features and workflow
    Given I am on the home page
    Then I should see "Fonctionnalités principales"
    And I should see "Identification SIRET automatique"
    And I should see "Gestion documentaire intégrée"
    And I should see "Comment ça marche ?"
    And I should see "1. Identification"
    And I should see "2. Documents"
    And I should see "3. Candidature"

  Scenario: Candidate homepage displays hero section
    Given I am on the candidate home page
    Then I should see "Votre candidature, adaptée à chaque marché public"

  Scenario: Candidate homepage displays value proposition
    Given I am on the candidate home page
    Then I should see "Candidater aux marchés publics n'a jamais été aussi simple"
    And I should see "automatiquement"
    And I should see "Identité de mon entreprise"
    And I should see "Certificats"

  Scenario: Candidate homepage displays advantages section
    Given I am on the candidate home page
    Then I should see "Quels sont les avantages"
    And I should see "Un formulaire unique et simplifié"
    And I should see "Récupération automatique de vos données"
    And I should see "Des informations justes et à jour"
    And I should see "Une transmission sécurisée"

  Scenario: Candidate homepage displays how it works section
    Given I am on the candidate home page
    Then I should see "Comment ça fonctionne"
    And I should see "Vous indiquez votre numéro de SIRET"
    And I should see "Les informations concernant votre entreprise"
    And I should see "Votre attestation est disponible"

  Scenario: Candidate homepage displays partner platforms section
    Given I am on the candidate home page
    Then I should see "Accédez aux marchés publics via nos plateformes partenaires"
    And I should see "Plateforme 1"
    And I should see "Plateforme 2"
    And I should see "Plateforme 3"

  Scenario: User visits the candidate homepage
    Given I am on the candidate home page
    Then I should see "Passe Marché"
    And I should see "Votre candidature, adaptée à chaque marché public"

  Scenario: User visits the buyer homepage
    Given I am on the buyer home page
    Then I should see "Passe Marché"
    And I should see "La plateforme de candidature simplifiée aux marchés publics"

  Scenario: Root URL displays buyer homepage content
    Given I am on the home page
    Then I should see "La plateforme de candidature simplifiée aux marchés publics"

  Scenario: Header displays navigation links
    Given I am on the home page
    Then I should see a link "Je suis un candidat" in the header
    And I should see a link "Je suis un acheteur public" in the header

  Scenario: Candidate link has active state on candidate page
    Given I am on the candidate home page
    Then the candidate navigation link should be active
    And the buyer navigation link should not be active

  Scenario: Buyer link has active state on buyer page
    Given I am on the buyer home page
    Then the buyer navigation link should be active
    And the candidate navigation link should not be active

  Scenario: Buyer link has active state on root page
    Given I am on the home page
    Then the buyer navigation link should be active
    And the candidate navigation link should not be active

  Scenario: Footer does not contain lorem ipsum
    Given I am on the home page
    Then I should not see "Lorem" in the footer
    And I should see "Accessibilité" in the footer
