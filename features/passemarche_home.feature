# frozen_string_literal: true

Feature: Passe Marché Home Page
  As a user visiting the Passe Marché application
  I want to see the home page
  So that I can confirm the application is working

  Scenario: User visits the home page
    Given I am on the home page
    Then I should see "Passe Marché"
    And I should see "Votre publication et votre analyse de candidatures"

  Scenario: User sees DSFR French government design
    Given I am on the home page
    Then I should see "République"
    And I should see "Française"

  Scenario: Buyer homepage displays advantages section
    Given I am on the buyer home page
    Then I should see "Quels sont les avantages"
    And I should see "Candidatures normalisées"
    And I should see "Gain de temps"
    And I should see "Fiabilité accrue"

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
    And I should see "Votre publication et votre analyse de candidatures"

  Scenario: Root URL displays buyer homepage content
    Given I am on the home page
    Then I should see "Gagner du temps dans vos marchés publics"

  Scenario: Buyer homepage displays how it works section
    Given I am on the buyer home page
    Then I should see "Comment ça fonctionne"
    And I should see "Paramétrez votre marché"
    And I should see "Bénéficiez d'un accompagnement clair"
    And I should see "Recevez des candidatures prêtes à être traitées"

  Scenario: Buyer homepage displays data examples section
    Given I am on the buyer home page
    Then I should see "Quelques exemples de données disponibles"
    And I should see "Les obligations légales et fiscales"
    And I should see "Les capacités techniques et professionnelles"

  Scenario: Buyer homepage displays partner platforms section
    Given I am on the buyer home page
    Then I should see "Accédez aux marchés publics via nos plateformes partenaires"
    And I should see "Plateforme 1"
    And I should see "Plateforme 2"
    And I should see "Plateforme 3"

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
