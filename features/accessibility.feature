@javascript
Feature: Accessibility
  As a user with accessibility needs
  I want the application to follow WCAG guidelines
  So that I can use it with assistive technologies

  Scenario: Home page is accessible
    Given I am on the home page
    Then the page should be accessible

  Scenario: Candidate home page is accessible
    Given I am on the candidate home page
    Then the page should be accessible

  Scenario: Buyer home page is accessible
    Given I am on the buyer home page
    Then the page should be accessible
