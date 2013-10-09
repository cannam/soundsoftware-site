# authors_controller_test.rb

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AuthorsControllerTest < ActionController::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :users, :authors, :authorships

  def test_truth
    assert true
  end

end
