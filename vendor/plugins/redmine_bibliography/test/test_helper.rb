# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')
require 'publications_controller'

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

class PublicationsControllerTest < ActionController::TestCase
  fixtures :publications, :authors, :bibtex_entries, :authorships

  def setup
  end

  def test_routing
    assert_routing(
        )
  end
