# vendor/plugins/redmine_bibliography/app/models/publication.rb

class Publication < ActiveRecord::Base
  unloadable

  has_many :authorships, :dependent => :destroy, :order => "auth_order ASC"
  has_many :authors, :through => :authorships, :uniq => true

  has_one :bibtex_entry, :dependent => :destroy

  validates_presence_of :title
  validates_length_of :authorships, :minimum => 1, :message => l("error_no_authors")

  accepts_nested_attributes_for :authorships
  accepts_nested_attributes_for :authors, :allow_destroy => true
  accepts_nested_attributes_for :bibtex_entry, :allow_destroy => true

  has_and_belongs_to_many :projects, :uniq => true

  before_save :set_initial_author_order

  named_scope :visible, lambda {|*args| { :include => :projects,
                                          :conditions => Project.allowed_to_condition(args.shift || User.current, :view_publication, *args) } }

  acts_as_activity_provider :type => 'publication',
                            :timestamp => "#{Publication.table_name}.created_at",
                            :find_options => {
                              :include => :projects,
                              :conditions => "#{Project.table_name}.id = projects_publications.project_id"
                            }

  acts_as_event :title => Proc.new {|o| o.title },
                :datetime => :created_at,
                :type => 'publications',
                :author => nil,
                #todo - need too move the cache from the helper to the model
                :description => Proc.new {|o| o.print_entry(:ieee)},
                :url => Proc.new {|o| {:controller => 'publications', :action => 'show', :id => o.id }}

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

  def notify_authors_publication_added(project)
    self.authors.each do |author|
      Rails.logger.debug { "Sending mail to \"#{self.title}\" publication authors." }
      Mailer.deliver_publication_added(author.user, self, project) unless author.user.nil?
    end
  end

  def notify_authors_publication_updated(project)
    self.authors.each do |author|
      Rails.logger.debug { "Sending mail to \"#{self.title}\" publication authors." }
      Mailer.deliver_publication_updated(author.user, self, project) unless author.user.nil?
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

  def print_bibtex_author_names
    # this authors are correctly sorted because the authorships model
    # already outputs the author names ASC by auth_order
    self.authorships.map{|a| a.name_on_paper}.join(' and ')
  end

  def print_entry(style)
    bib = BibTeX::Entry.new

    bib.author = self.print_bibtex_author_names
    bib.title = self.title

    self.bibtex_entry.attributes.keys.sort.each do |key|
      value = self.bibtex_entry.attributes[key].to_s
      next if key == 'id' or key == 'publication_id' or value == ""

      if key == "entry_type"
        bib.type = BibtexEntryType.find(self.bibtex_entry.entry_type).name
      else
        bib[key.to_sym] = value
      end
    end

    if style == :ieee
      CiteProc.process bib.to_citeproc, :style => :ieee, :format => :html
    else
      bibtex = bib.to_s :include => :meta_content
      bibtex.strip!
      logger.error { bibtex }
    end
  end
end
