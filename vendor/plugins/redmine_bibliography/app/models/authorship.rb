class Authorship < ActiveRecord::Base
  unloadable 
  
  belongs_to :author
  belongs_to :publication
  
  accepts_nested_attributes_for :author
  accepts_nested_attributes_for :publication
  
  attr_accessor :is_user, :author_user_id, :search_name, :identify_author, :search_results
  before_save :associate_author_user

  named_scope :like_unique, lambda {|q| 
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name_on_paper) LIKE :s OR LOWER(email) LIKE :s", {:s => s}],
     :order => 'name_on_paper',
     :group => "name_on_paper, institution, email"
    }
  }

  named_scope :like, lambda {|q| 
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name_on_paper) LIKE :s OR LOWER(email) LIKE :s", {:s => s}],
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
    case self.identify_author
      when "no"
        author = Author.new
        author.save
        self.author_id = author.id
      else
        selected = self.search_results
        selected_classname = Kernel.const_get(selected.split('_')[0])
        selected_id = selected.split('_')[1]
        object = selected_classname.find(selected_id)

        if object.respond_to? :name_on_paper
          # Authorship
          self.author_id = object.author.id
        else
          # User
          unless object.author.nil?
            self.author_id = object.author.id
          else
            author = Author.new
            object.author = author
            object.save
            self.author_id = object.author.id
          end
        end
    end      
  end
end
