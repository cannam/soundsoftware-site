class Authorship < ActiveRecord::Base
  unloadable 
  
  belongs_to :author
  belongs_to :publication
  
  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication
  
  attr_accessor :is_user, :author_user_id, :search_name, :identify_author, :search_results
  before_save :associate_author_user

  named_scope :like, lambda {|q| 
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name_on_paper) LIKE :s", {:s => s}],
     :order => 'name_on_paper'
    }
  }
  
  def name
    return self.name_on_paper
  end
  
  def <=>(authorship)
    name.downcase <=> authorship.name.downcase
  end
    
  def mail
    return self.email
  end
  
  protected 
  def associate_author_user 
    logger.error { "Before Save: associate_author_user" }   

    case self.is_user
      when "0"
        author = Author.find(self.author_user_id)
        self.author_id = author.id        
      when "1"
        user = User.find(self.author_user_id)
        
        if user.author.nil?
          author = Author.new :name => self.name_on_paper
          author.save
          self.author_id = author.id
          user.author = author
          user.save
        else
          author = user.author
          self.author_id = author.id
        end        
      else
        author = Author.new :name => self.name_on_paper
        logger.error { "SAVED AUTHOR" }
        author.save
        self.author_id = author.id
        
      end
  end
end
