Feature: Candidate application flow

  As a candidate
  I want to complete the application process step by step
  So that I can submit my application for a public market

  Background:
    Given a public market exists
    And a candidate starts a new application

  Scenario: Candidate completes the application flow successfully
    When the candidate visits the "market_and_company_information" step
    Then they should see the "market_and_company_information" step
    When the candidate visits the "exclusion_criteria" step
    Then they should see the "exclusion_criteria" step
    When the candidate visits the "economic_capacities" step
    Then they should see the "economic_capacities" step
    When the candidate visits the "technical_capacities" step
    Then they should see the "technical_capacities" step
    When I proceed to the summary step
    Then I should see a summary of my application
    When I submit my application
