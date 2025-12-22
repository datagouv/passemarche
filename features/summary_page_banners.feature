# frozen_string_literal: true

@summary_page_banners
Feature: Summary Page Banners (FAS-324)
  En tant que candidat
  Je souhaite être informé clairement des risques de non remplissage des éléments
  Afin de comprendre immédiatement que ma candidature nécessite une action de ma part

  Background:
    Given an editor exists

  # RG1-3: Information banner when buyer has optional attributes
  Scenario: Display info banner when buyer has optional market attributes
    Given a public market with optional market attributes exists
    And a market application exists for this market
    When I visit the candidate summary page
    Then I should see the buyer additional info banner

  Scenario: No info banner when buyer has only mandatory market attributes
    Given a public market with only mandatory market attributes exists
    And a market application exists for this market
    When I visit the candidate summary page
    Then I should not see the buyer additional info banner

  # RG4: Exclusion motifs warning when attestation not confirmed
  Scenario: Display exclusion motifs warning when attestation is not confirmed
    Given a public market with motifs exclusion attributes exists
    And a market application exists with attestation not confirmed
    When I visit the candidate summary page
    Then I should see the exclusion motifs warning banner

  Scenario: No exclusion motifs warning when attestation is confirmed
    Given a public market with motifs exclusion attributes exists
    And a market application exists with attestation confirmed
    When I visit the candidate summary page
    Then I should not see the exclusion motifs warning banner

  # RG5: Missing mandatory motifs exclusion data banner
  Scenario: Display missing documents banner when mandatory motifs exclusion data is missing
    Given a public market with mandatory motifs exclusion attributes exists
    And a market application exists without motifs exclusion data
    When I visit the candidate summary page
    Then I should see the missing mandatory motifs exclusion banner

  Scenario: No missing documents banner when mandatory motifs exclusion data is present
    Given a public market with mandatory motifs exclusion attributes exists
    And a market application exists with motifs exclusion data filled
    When I visit the candidate summary page
    Then I should not see the missing mandatory motifs exclusion banner

  Scenario: No missing documents banner when there are no mandatory motifs exclusion attributes
    Given a public market with optional market attributes exists
    And a market application exists for this market
    When I visit the candidate summary page
    Then I should not see the missing mandatory motifs exclusion banner

  # RG6: Footer disclaimer
  Scenario: Display footer disclaimer on summary page
    Given a public market with only mandatory market attributes exists
    And a market application exists for this market
    When I visit the candidate summary page
    Then I should see the submission disclaimer
