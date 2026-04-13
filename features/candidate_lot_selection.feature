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

  Scenario: Candidate is not redirected to lot selection when lots are already selected
    When the candidate selects the first lot
    And the candidate submits the lot selection form
    And the candidate reconnects to the application
    Then the candidate should be on the company identification step

  Scenario: Summary submission goes through lot selection when market has lots
    Given the candidate revisits the summary page
    Then the summary should route submission to lot selection
    When the candidate clicks submit from summary
    Then the candidate should remain on the lot selection page

  Scenario: Summary keeps direct submit when market has no lots
    Given a public market without lots exists
    And a candidate starts a new application for a market without lots
    And the candidate revisits the summary page for market without lots
    Then the summary should have a direct submit button

  Scenario: Progress card shows field counter with no fields filled
    Then the candidate should see the field counter showing "0/1 champs"
    And the progress card CTA should show "Préparer"

  Scenario: CA8 - Progress card CTA shows "Modifier" when fields are filled
    Given the candidate has filled all fields
    And the candidate revisits the lot selection page
    Then the candidate should see the field counter in green
    And the progress card CTA should show "Modifier"
