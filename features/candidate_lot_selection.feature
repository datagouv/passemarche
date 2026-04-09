Feature: Candidate lot selection

  As a candidate
  I want to select lots that interest me before filling in my application
  So that my bid targets the right market segments

  Background:
    Given a public market with lots exists
    And a candidate starts a new application for a market with lots

  Scenario: Candidate is redirected to lot selection after login
    Then they should see the lot selection page
    And they should see a checkbox for each lot

  Scenario: Candidate can select lots and access the wizard
    When the candidate selects the first lot
    And the candidate submits the lot selection form
    Then the candidate should be on the summary step

  Scenario: Lot selection page does not appear when market has no lots
    Given a public market without lots exists
    And a candidate starts a new application for a market without lots
    Then the candidate should be on the company identification step

  Scenario: Candidate cannot proceed without selecting a lot
    When the candidate submits the lot selection form without selecting any lot
    Then the candidate should see an error about selecting at least one lot
    And the candidate should remain on the lot selection page

  Scenario: Candidate cannot exceed lot_limit
    Given the public market has a lot limit of 1
    When the candidate selects all available lots
    And the candidate submits the lot selection form
    Then the candidate should see an error about the lot limit
    And the candidate should remain on the lot selection page
