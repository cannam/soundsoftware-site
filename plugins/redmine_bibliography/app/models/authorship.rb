class Authorship < ActiveRecord::Base
  unloadable

  belongs_to :author
  belongs_to :publication

  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication

  validates_presence_of :name_on_paper

  attr_writer :search_author_id , :search_author_class
  attr_writer :search_author_tie

  ### attr_accessor :search_results, :identify_author
  ## attr_writer :search_author_class

  before_save :set_author
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
      aclass = ""
    else
      aclass = "Author"
    end

    @search_author_class || aclass
  end

  def search_author_id
    if self.author.nil?
      authid = ""
    else
      authid = author_id
    end

    @search_author_id || authid
  end

  def search_author_tie
    if self.author.nil?
      auth_tie = false
    else
      auth_tie = true
    end

    @search_author_tie || auth_tie
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

  private

  def set_author
    # do we want to associate the authorship
    #  with an existing author/user?
    if @search_author_tie
      # if an author, simply associates with it
      # if an user, checks if it has already an author associated with it
      #   if so, associates with that author
      #   otherwise, creates a new author

      case @search_author_class
      when ""
        author = Author.new
        author.save

      when "User"
        user = User.find(@search_author_id)

        if user.author.nil?
          # User w/o author:
          # create new author and update user
          author = Author.new
          author.save
          user.author = author
          user.save
        else
          author = user.author
        end

      when "Author"
        author = Author.find(@search_author_id)
      end

    # if we don't want to associate with an existing author/user
    else
      # todo: should we delete any previously existing relationship?
      author = Author.new
      author.save
    end

    self.author = author
  end
end
