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
  
end
