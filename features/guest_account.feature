Feature: Guest account
  As an unregistered visitor
  In order to see any entities
  I want to use a guest account
  
  
  Scenario: View the system as guest
    Given user "guest" is allowed to "view" collection "Default" through credential "guests"
    When I go to the gallery page
    Then I should not be on the login page
    
    
  Scenario: See a login button when not logged in
    Given user "guest" is allowed to "view" collection "Default" through credential "guests"
    When I go to the expert search page
    Then I should see element "a[href='/login']" within "#menu"
    And I should not see "Profil bearbeiten"
    
    
  Scenario: View the profile page as guest
    Given user "guest" is allowed to "view" collection "Default" through credential "guests"
    When I go to the profile page for user "guest"
    Then I should be on the denied page
