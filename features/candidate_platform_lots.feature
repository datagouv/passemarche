Feature: Candidate receives the lots chosen on the platform

  As a candidate who already chose my lots on my procurement platform
  I want Passe Marché to reuse them
  So that I do not enter them twice

  Background:
    Given a multi-type public market with lots exists
    And an authorized and active editor exists with credentials "test_editor_id" and "test_editor_secret"
    And I have a valid access token
    And the multi-type market is published by the editor
    And the multi-type market asks for the Qualibat certificate on works lots

  Scenario: The transmitted lots are shown read-only
    When the platform creates an application with the lots "Lot 1 - Gros œuvre"
    And the candidate opens the application created by the platform
    And the candidate visits the lots recap
    Then the candidate should see 1 transmitted lot without being able to edit the lots
    And the candidate should be told to change the lots on the platform

  Scenario: An unknown lot is refused
    When the platform creates an application with a lot of another market
    Then the API should refuse the application because of the lots
    And no application should have been created

  Scenario: A re-candidature with other lots replaces the selection and keeps the answers
    Given the platform created an application with the lots "Lot 1 - Gros œuvre"
    And the candidate answered the INSEE question
    When the platform creates an application with the lots "Lot 2 - Charpente"
    Then the application should only declare the lot "Lot 2 - Charpente"
    And the INSEE answer should be kept

  Scenario: A lot of a new type adds its fields and warns the candidate
    Given the platform created an application with the lots "Lot 3 - Prestations SI"
    And the APIs of the services lot have been fetched
    And API fetches are queued without being run
    When the platform creates an application with the lots "Lot 3 - Prestations SI" and "Lot 1 - Gros œuvre"
    Then only the Qualibat API should be queued for fetching
    When the candidate opens the application created by the platform
    And the candidate visits the API data recovery step
    Then the candidate should be warned that the platform added a new lot type

  Scenario: Without transmitted lots the candidate chooses the lots in Passe Marché
    When the platform creates an application without lots
    And the candidate opens the application created by the platform
    And the candidate visits the lots recap
    Then they should see lots grouped by type
