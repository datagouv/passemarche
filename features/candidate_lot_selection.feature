Feature: Candidate lot selection

  As a candidate
  I want to select lots that interest me before filling in my application
  So that my bid targets the right market segments

  Background:
    Given a public market with lots exists
    And a candidate starts a new application for a market with lots

  Scenario: Candidate sees lot selection in the wizard flow
    When the candidate visits the lot selection step
    Then the candidate should be on the lot selection step
    And they should see a checkbox for each lot

  Scenario: Lot selection step is skipped when market has no lots
    Given a public market without lots exists
    And a candidate starts a new application for a market without lots
    When the candidate visits the lot selection step
    Then the candidate should be on the api data recovery status step

  Scenario: Candidate can select lots and reach the preparation page
    When the candidate visits the lot selection step
    And the candidate selects the first lot
    And the candidate clicks Suivant
    Then the candidate should be on the lot selection step
    And the candidate should see the preparation page

  Scenario: Candidate cannot proceed without selecting a lot
    When the candidate visits the lot selection step
    And the candidate submits the lot selection step without selecting any lot
    Then the candidate should see an error about selecting at least one lot
    And the candidate should remain on the lot selection step

  Scenario: Candidate cannot exceed lot_limit
    Given the public market has a lot limit of 1
    When the candidate visits the lot selection step
    And the candidate selects all available lots
    And the candidate submits the lot selection step without selecting any lot
    Then the candidate should see an error about the lot limit
    And the candidate should remain on the lot selection step

  Scenario: Preparation page shows Commencer when form not started
    When the candidate visits the lot selection step
    And the candidate selects the first lot
    And the candidate clicks Suivant
    Then the candidate should see the preparation page
    And the candidate should see the complete button

  Scenario: Preparation page shows how it works even when form is started
    Given the candidate has already started the form
    When the candidate visits the preparation page
    Then the candidate should see the preparation page
    And the candidate should see the how it works section
    And the candidate should see the modify button

  Scenario: Candidate can edit lots from the preparation page
    When the candidate visits the lot selection step
    And the candidate selects the first lot
    And the candidate clicks Suivant
    And the candidate clicks the edit lots button
    Then the candidate should be on the lot selection step

  Scenario: Candidate is redirected to company identification when reconnecting
    When the candidate visits the lot selection step
    And the candidate selects the first lot
    And the candidate clicks Suivant
    And the candidate reconnects to the application
    Then the candidate should be on the company identification step
