class Authorship < ActiveRecord::Base
  belongs_to :author
  belongs_to :publication
  
  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication
  
 
  # setter and getter for virtual attribute :author search
  def author_search
  end 
  
  def author_search=(string)
  end

  # setter and getter for virtual attribute :user_id
  def user_id
    logger.error { "USER ID SETTER" }
    logger.error { self }
    logger.error { "END USER ID SETTER" }
    
  end 
  
  def user_id=(uid)
    # process the user id
    # test for undefined 

  end
end
