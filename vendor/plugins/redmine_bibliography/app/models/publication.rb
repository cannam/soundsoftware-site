# vendor/plugins/redmine_bibliography/app/models/publication.rb

class Publication < ActiveRecord::Base
  unloadable
  
  has_many :authorships, :dependent => :destroy, :order => "auth_order ASC"
  has_many :authors, :through => :authorships, :uniq => true
  
  has_one :bibtex_entry, :dependent => :destroy

  validates_presence_of :title

  accepts_nested_attributes_for :authorships
  accepts_nested_attributes_for :authors, :allow_destroy => true
  accepts_nested_attributes_for :bibtex_entry, :allow_destroy => true
  
  has_and_belongs_to_many :projects, :uniq => true
  
  before_save :set_initial_author_order
  after_save :notify_authors

  # Ensure error message uses proper text instead of
  # bibtex_entry.entry_type (#268).  There has to be a better way to
  # do this!
  def self.human_attribute_name(k)
    if k == 'bibtex_entry.entry_type'
      l(:field_entry_type)
    else
      super
    end
  end

  # Returns the mail adresses of users that should be notified
  def notify_authors
        
    self.authors.each do |author|
      Rails.logger.debug { "Sending mail to \"#{self.title}\" publication authors." }
      Mailer.deliver_publication_added(author.user, self) unless author.user.nil?
    end
    
  end
  
  
  def set_initial_author_order
    authorships = self.authorships
    
    logger.debug { "Publication \"#{self.title}\" has #{authorships.size} authors." }
    
    authorships.each_with_index do |authorship, index|
      if authorship.auth_order.nil?
         authorship.auth_order = index
      end
    end    
  end
  
  
  
  
end
