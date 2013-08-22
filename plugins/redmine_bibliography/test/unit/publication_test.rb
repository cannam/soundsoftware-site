require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class PublicationTest < ActiveSupport::TestCase
    self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"

    fixtures :publications, :authorships

    # Replace this with your real tests.
    def test_truth
        assert true
    end

    def test_relationships
        # test authorships - publication relationship
        publication = Publication.find(1)

        assert publication.authorships.count == 4
    end

end
