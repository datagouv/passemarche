Feature: Test isolation
  A scenario without JavaScript keeps its data whatever another thread
  takes from the connection pool.

  Scenario: Data created by a scenario survives a request and another thread taking a connection
    Given a market application exists
    And I am on the home page
    When another thread holds a database connection
    Then the market application is still found
