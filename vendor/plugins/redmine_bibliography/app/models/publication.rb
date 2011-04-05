# vendor/plugins/redmine_bibliography/app/models/publication.rb

class Publication < ActiveRecord::Base
  has_many :authorships
  has_many :authors, :through => :authorships

  validates_presence_of :title
  
  attr_writer :current_step

  def current_step
    @current_step || steps.first
  end
  
  def steps
    %w[new review]
  end


end
