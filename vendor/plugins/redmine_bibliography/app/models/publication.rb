class Publication < ActiveRecord::Base
  has_many :authorships
  has_many :authors, :through => :authorships
end
