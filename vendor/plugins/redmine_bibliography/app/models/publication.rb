# vendor/plugins/redmine_bibliography/app/models/publication.rb

class Publication < ActiveRecord::Base
  unloadable


  has_many :authorships
  has_many :authors, :through => :authorships
  has_one :bibtex_entry

  validates_presence_of :title
  
  accepts_nested_attributes_for :authors, :bibtex_entry
  
  attr_writer :current_step

  def current_step
    @current_step || steps.first
  end
  
  def steps
    %w[new review]
  end
  
  def next_step
    self.current_step = steps[steps.index(current_step)+1]
  end

  def previous_step
    self.current_step = steps[steps.index(current_step)-1]
  end
  
  def first_step?
    current_step == steps.first
  end

end
