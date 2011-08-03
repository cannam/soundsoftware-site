# vendor/plugins/redmine_bibliography/app/models/publication.rb

class Publication < ActiveRecord::Base
  unloadable
  
  has_many :authorships, :dependent => :destroy
  has_many :authors, :through => :authorships, :uniq => true
  
  has_one :bibtex_entry, :dependent => :destroy

  validates_presence_of :title

  accepts_nested_attributes_for :authorships
  accepts_nested_attributes_for :authors, :allow_destroy => true
  accepts_nested_attributes_for :bibtex_entry, :allow_destroy => true
  
  has_and_belongs_to_many :projects, :uniq => true
  
  after_save :set_initial_author_order
  
  def set_initial_author_order
    authorships = self.authorships
    
    logger.debug { "Publication \"#{self.title}\" has #{authorships.size} authors." }
    
    authorships.each_with_index do |authorship, index|
      if authorship.auth_order.nil?
         authorship.auth_order = index
         authorship.save!
      end
    end    
  end
  
  
  
  
end
