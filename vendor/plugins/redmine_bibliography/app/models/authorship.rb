class Authorship < ActiveRecord::Base
  unloadable 
  
  belongs_to :author
  belongs_to :publication
  
  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication
  
  
  # setter and getter for virtual attribute :user_id
  def user_id    
  end 
  
  def user_id=(uid)  
    if uid.blank?
      author = Author.new :name => self.name_on_paper
      author.save!
      self.author_id = author.id
    else
      user = User.find(uid)                         
      
      if user.author.nil?      
        # TODO: should reflect the name_on_paper parameter
        author = Author.new :name => self.name_on_paper
        author.save!
        user.author = author
        user.save!
      else
        self.author_id = user.author.id        
      end
    end    
  end
end
