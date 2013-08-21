ENV['RAILS_ENV'] ||= 'test'

# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../app/controllers/publications_controller')

class BibliographyControllerTest < ActionController::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"

  fixtures :authors

  def setup

  end

  def test_publication
    pub = Publication.first

    assert 1 == 0
  end

  # def test_routing
  #   assert_routing(
  #         {:method => :get, :path => '/requirements'},
  #         :controller => 'requirements', :action => 'index'
  #       )
  # end

end
