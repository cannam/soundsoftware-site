# author_test.rb

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AuthorTest < ActiveSupport::TestCase
    self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
    fixtures :users, :authors, :authorships

    def test_relationships
        author = Author.find(1)
        assert author.authorships.first.name_on_paper == "Yih-Farn R. Chen"
    end

end
