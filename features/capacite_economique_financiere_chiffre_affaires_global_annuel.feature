# frozen_string_literal: true

@capacite_economique_financiere
Feature: Capacité économique et financière - Chiffre d'affaires global annuel
  En tant que candidat à un marché public
  Je veux pouvoir renseigner le chiffre d'affaires de mon entreprise sur 3 années
  Afin de démontrer mes capacités économiques et financières

  Background:
    Given a public market with capacite_economique_financiere_chiffre_affaires_global_annuel field exists
    And a candidate starts an application for this market

  Scenario: Display of 3x3 grid form
    When I visit the economic capacities step
    Then I should see a table with headers:
      | Année | Chiffre d'affaires (€) | % CA dans le secteur du marché | Fin de l'exercice |
    And I should see 3 rows with labels:
      | Année N-1 |
      | Année N-2 |
      | Année N-3 |

  Scenario: Successful form submission with valid data
    When I visit the economic capacities step
    And I fill in the turnover data:
      | year   | turnover | percentage | fiscal_year_end |
      | year_1 | 500000   | 75         | 2023-12-31      |
      | year_2 | 450000   | 80         | 2022-12-31      |
      | year_3 | 400000   | 70         | 2021-12-31      |
    And I click "Suivant"
    Then the economic capacity form should be submitted successfully
    And the data should be saved with correct structure

  Scenario: Validation errors for missing required fields
    When I visit the economic capacities step
    And I fill in partial turnover data:
      | year   | turnover | percentage | fiscal_year_end |
      | year_1 | 500000   |            | 2023-12-31      |
      | year_2 |          | 80         |                 |
      | year_3 | 400000   | 70         | 2021-12-31      |
    And I click "Suivant"
    Then I should see validation errors:
      | error |
      | year_1.market_percentage is required |
      | year_2.turnover is required |
      | year_2.fiscal_year_end is required |
    And the economic capacity form should not be submitted

  Scenario: Validation errors for invalid data types
    When I visit the economic capacities step
    And I fill in invalid turnover data:
      | year   | turnover    | percentage | fiscal_year_end |
      | year_1 | not_number  | 150        | 2023-02-30      |
      | year_2 | -1000       | -5         | invalid_date    |
      | year_3 | 400000      | 70         | 2021-12-31      |
    And I click "Suivant"
    Then I should see validation errors:
      | error |
      | year_1.market_percentage must be between 0 and 100 |
      | year_2.turnover must be a positive integer |
      | year_2.market_percentage must be between 0 and 100 |
      | year_1.fiscal_year_end must be in YYYY-MM-DD format |
      | year_2.fiscal_year_end must be in YYYY-MM-DD format |
    And the economic capacity form should not be submitted

  Scenario: Display of submitted data in summary
    Given I have submitted valid turnover data:
      | year   | turnover | percentage | fiscal_year_end |
      | year_1 | 500000   | 75         | 2023-12-31      |
      | year_2 | 450000   | 80         | 2022-12-31      |
      | year_3 | 400000   | 70         | 2021-12-31      |
    When I visit the summary step
    Then I should see the turnover data displayed in a table:
      | year      | turnover  | percentage | fiscal_year_end |
      | Année N-1 | 500 000 € | 75 %       | 31/12/2023      |
      | Année N-2 | 450 000 € | 80 %       | 31/12/2022      |
      | Année N-3 | 400 000 € | 70 %       | 31/12/2021      |

  Scenario: STI class verification for capacite_economique_financiere_chiffre_affaires_global_annuel
    When I visit the economic capacities step
    Then the form should have a hidden type field with value "CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel"
    When I fill in valid turnover data and submit
    Then the economic capacity response should be created with class "MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel"
    And the response should have the correct JSON structure

  Scenario: Data persistence across navigation
    When I visit the economic capacities step
    And I fill in turnover data:
      | year   | turnover | percentage | fiscal_year_end |
      | year_1 | 500000   | 75         | 2023-12-31      |
    And I click "Suivant"
    And I navigate back to the economic capacities step
    Then the turnover field for year_1 should contain "500000"
    And the percentage field for year_1 should contain "75"
    And the fiscal_year_end field for year_1 should contain "2023-12-31"
