class Authorship < ActiveRecord::Base
  belongs_to :author
  belongs_to :publication
  
  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication
  
  # setter and getter for virtual attribute :user_id
  def user_id    
  end 
  
  def user_id=(uid)
    if User.find(uid).author.nil?      
      User.find(uid).author = Author.new :name => User.find(uid).name
    end    
  end
end
