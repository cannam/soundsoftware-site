require File.dirname(__FILE__) + '/../test_helper'

class AuthorTest < ActiveSupport::TestCase
  fixtures :authors

  # Replace this with your real tests.
  def test_truth
    luis = Author.first

    assert true
  end
end
