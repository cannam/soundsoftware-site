class Author < ActiveRecord::Base
  has_many :authorships
  has_many :publications, :through => :authorships
end
