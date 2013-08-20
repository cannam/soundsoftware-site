ENV['RAILS_ENV'] ||= 'test'

# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../app/controllers/publications_controller')

# Ensure that we are using the temporary fixture path
# Engines::Testing.set_fixture_path

class BibliographyControllerTest < ActionController::TestCase
  # fixtures :all

  def setup
  end

  def test_publication
    assert 1 == 0
  end

  def test_routing
    assert_routing(
          {:method => :get, :path => '/requirements'},
          :controller => 'requirements', :action => 'index'
        )
  end

end
