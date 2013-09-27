class Authorship < ActiveRecord::Base
  unloadable

  belongs_to :author
  belongs_to :publication

  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication

  validates_presence_of :name_on_paper

  attr_writer :search_author_id, :search_author_class
  attr_writer :search_author_tie

  ### attr_accessor :search_results, :identify_author
  ## attr_writer :search_author_class

  before_create :set_author
  before_update :delete_publication_cache

  # tod: review scope of ordering
  acts_as_list :column => 'auth_order'

  # todo: review usage of scope --lf.20130108
  scope :like_unique, lambda {|q|
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name_on_paper) LIKE :s OR LOWER(email) LIKE :s", {:s => s}],
     :order => 'name_on_paper',
     :group => "name_on_paper, institution, email"
    }
  }

  # todo: review usage of scope --lf.20130108
  scope :like, lambda {|q|
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name_on_paper) LIKE :s OR LOWER(email) LIKE :s", {:s => s}],
     :order => 'name_on_paper'
    }
  }

  def search_author_class
    # Authorship must always have an Author
    # unless it hasn't been saved yet
    # using default setter (attr_writer)

    if self.author.nil?
      return ""
    else
      return "Author"
    end
  end

  def search_author_id
    if self.author.nil?
      return ""
    else
      return self.author_id
    end
  end

  def search_author_tie
    if self.author.nil?
      return false
    else
      return true
    end

  end

  def name
    return self.name_on_paper
  end

  def <=>(authorship)
    name.downcase <=> authorship.name.downcase
  end

  def mail
    return self.email
  end

  protected

  def delete_publication_cache
    publication = Publication.find(self.publication_id)
    Rails.cache.delete "publication-#{publication.id}-ieee"
    Rails.cache.delete "publication-#{publication.id}-bibtex"
  end

  def set_author
    # if an author, simply associates with it
    # if an user, checks if it has already an author associated with it
    # if so, assicoates with that author
    # otherwise, creates a new author

    logger.error { "%%%%%%%%%%%%%%% Associate Author User %%%%%%%%%%%%%%" }

    logger.error { "EU #{self.to_yaml}" }
    logger.error { "Class: #{search_author_class}" }
    logger.error { "ID #{search_author_id}" }

    case self.search_author_class
    when ""
      logger.debug { "Adding new author to the database." }
      author = Author.new
      author.save

    when "User"
      # get user id
      user = User.find(self.search_author_id)
      logger.error { "Found user with this ID: #{user.id}" }

      if user.author.nil?
        logger.error { "The user has no author... creating one!" }

        # User w/o author:
        # create new author and update user
        author = Author.new
        author.save
        user << author
      else
        logger.error { "found an author!" }
        author = user.author
      end

    when "Author"
      author = Author.find(self.search_author_id)
    end

    self.author = author
  end
end
