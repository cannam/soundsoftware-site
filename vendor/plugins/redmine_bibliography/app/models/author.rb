class Author < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :publications, :through => :authorships

  belongs_to :user

  def <=>(author)
    name.downcase <=> author.name.downcase
  end
  
  named_scope :like, lambda {|q| 
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name) LIKE :s", {:s => s}],
     :order => 'name'
    }
  }

end
