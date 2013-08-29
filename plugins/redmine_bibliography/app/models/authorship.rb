class Authorship < ActiveRecord::Base
  unloadable

  belongs_to :author
  belongs_to :publication

  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication

  validates_presence_of :name_on_paper

  attr_accessor :search_author_class, :search_author_id, :search_name, :search_results, :identify_author

  before_create :associate_author_user
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

  def associate_author_user
    case self.search_author_class
    when ""
      logger.debug { "Unknown Author to be added..." }
    when "User"
      author = Author.new
      author.save
      self.author_id = author.id

    when "Author"
      selected = self.search_results
      selected_classname = Kernel.const_get(self.search_author_class)
      selected_id = self.search_author_id
      object = selected_classname.find(selected_id)

      if object.respond_to? :name_on_paper
        # Authorship
        self.author_id = object.author.id
      else
        # User
        unless object.author.nil?
          self.author_id = object.author.id
        else
          author = Author.new
          object.author = author
          object.save
          self.author_id = object.author.id
        end
      end
    end
  end
end
