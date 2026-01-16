@capacite_economique_financiere
Feature: Capacité économique et financière - Effectifs moyens annuels
  En tant que candidat à un marché public
  Je veux pouvoir renseigner les effectifs moyens de mon entreprise sur 3 années
  Afin de démontrer mes capacités économiques et financières

  Background:
    Given a public market with capacite_economique_financiere_effectifs_moyens_annuels field exists
    And a candidate starts an application for this market (effectifs moyens annuels)

  Scenario: Display of table form with three columns
    When I visit the economic capacities step (effectifs moyens annuels)
    Then I should see effectifs form with table headers:
      | Année | Effectif moyen | Personnel d'encadrement |

  Scenario: Successful form submission with valid data
    When I visit the economic capacities step (effectifs moyens annuels)
    And I fill in average staff data:
      | year   | year_value | average_staff | management_staff |
      | year_1 | 2024       | 30            | 5                |
      | year_2 | 2023       | 32            | 7                |
      | year_3 | 2022       | 35            | 8                |
    And I click "Suivant"
    Then the effectifs form should be submitted successfully
    And the year data should be saved with correct structure

  Scenario: Partial data submission is valid (all fields optional)
    When I visit the economic capacities step (effectifs moyens annuels)
    And I fill in partial average staff data:
      | year   | year_value | average_staff | management_staff |
      | year_1 | 2024       |               |                  |
      | year_2 |            | 32            | 7                |
      | year_3 | 2022       | 35            |                  |
    And I click "Suivant"
    Then the effectifs form should be submitted successfully

  Scenario: Validation errors for invalid data types
    When I visit the economic capacities step (effectifs moyens annuels)
    And I fill in invalid average staff data:
      | year   | year_value | average_staff | management_staff |
      | year_1 | not_a_year | -5            | -3               |
      | year_2 | 2023       | not_a_number  | 7                |
      | year_3 | 2022       | 35            | 8                |
    And I click "Suivant"
    Then I should see validation errors:
      | error |
      | year_1.year must be a valid year |
      | year_1.average_staff must be a positive integer |
      | year_1.management_staff must be a positive integer |
    And the effectifs form should not be submitted

  Scenario: Display of submitted data in summary
    Given I have submitted valid average staff data:
      | year   | year_value | average_staff | management_staff |
      | year_1 | 2024       | 30            | 5                |
      | year_2 | 2023       | 32            | 7                |
      | year_3 | 2022       | 35            | 8                |
    When I visit the effectifs summary step
    Then I should see the average staff data displayed:
      | year      | year_value | average_staff | management_staff |
      | Année n-1 | 2024       | 30            | 5                |
      | Année n-2 | 2023       | 32            | 7                |
      | Année n-3 | 2022       | 35            | 8                |

  Scenario: STI class verification for capacite_economique_financiere_effectifs_moyens_annuels
    When I visit the economic capacities step (effectifs moyens annuels)
    Then the form should have a hidden type field with value "CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels"
    When I fill in valid average staff data and submit
    Then the effectifs response should be created with class "MarketAttributeResponse::CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels"
    And the effectifs response should have the correct JSON structure

  Scenario: Data persistence across navigation
    When I visit the economic capacities step (effectifs moyens annuels)
    And I fill in average staff data:
      | year   | year_value | average_staff | management_staff |
      | year_1 | 2024       | 30            | 5                |
    And I click "Suivant"
    And I navigate back to the economic capacities step (effectifs moyens annuels)
    Then the year field for year_1 should contain "2024"
    And the average_staff field for year_1 should contain "30"
    And the management_staff field for year_1 should contain "5"
