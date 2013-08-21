require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AuthorsControllerTest < ActionController::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :users, :authors

  def test_users_authors_relationship
    assert Author.first.user.name == "redMine Admin"
  end

end
