class Authorship < ActiveRecord::Base
  belongs_to :author
  belongs_to :publication
  
 
  # setter and getter for virtual attribute :author search
  def author_search
  end 
  
  def author_search=(string)
  end
  
end
