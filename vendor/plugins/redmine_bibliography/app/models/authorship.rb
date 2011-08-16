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

  end
end
