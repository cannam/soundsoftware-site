class Author < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :publications, :through => :authorships

  belongs_to :user
  
end
