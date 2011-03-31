class Publication < ActiveRecord::Base
  has_many :authorships
  has_many :authors, :through => :authorships

  validates_presence_of :title

end
