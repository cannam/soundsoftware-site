class Author < ActiveRecord::Base
  unloadable

  has_many :authorships, :dependent => :destroy
  has_many :publications, :through => :authorships

#  validates_length_of :authorships, :minimum => 1, :message => "need to have at least 1 associated authorship - author not saved."

end
