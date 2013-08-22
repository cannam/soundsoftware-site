# publication_test

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

        assert 4, publication.authorships.count
    end

    def test_new_publication_validations
        pub = Publication.create

        assert !pub.valid?, "!pub.valid?"
        assert_equal 2, pub.errors.count, "Number of errors"
        assert_equal ["can't be blank"], pub.errors[:title]
        assert_equal ["Please add at least one author to this publication."], pub.errors[:authorships]
    end

end
