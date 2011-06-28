class Author < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :publications, :through => :authorships

  belongs_to :user
  
  named_scope :like, lambda {|q| 
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name) LIKE :s", {:s => s}],
     :order => 'name'
    }
  
end
