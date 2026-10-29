Feature: Candidate changes the type of the declared lots

  As a candidate
  I want my application to follow the lots I declare
  So that I only provide the documents my lots require

  Background:
    Given a multi-type public market with lots exists
    And the multi-type market asks for the Qualibat certificate on works lots
    And a candidate starts a new application for the multi-type market

  Scenario: Adding a works lot after the API step fetches the works APIs
    Given the candidate declared only the services lot
    And the APIs of the services lot have been fetched
    And API fetches are queued without being run
    When the candidate adds the works lot to the declared lots
    And the candidate visits the API data recovery step
    Then only the Qualibat API should be queued for fetching
    And the Qualibat API should be pending

  Scenario: Removing the works lot removes the Qualibat certificate from the summary
    Given the candidate declared the works and services lots
    And the candidate uploaded "qualibat.pdf" as Qualibat certificate
    When the candidate keeps only the services lot
    And the candidate visits the summary step
    Then the candidate should not see "qualibat.pdf" on the summary
