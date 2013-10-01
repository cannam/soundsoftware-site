class Author < ActiveRecord::Base
  unloadable

  has_many :authorships, :dependent => :destroy
  has_many :publications, :through => :authorships

  belongs_to :user

  def <=>(author)
    name.downcase <=> author.name.downcase
  end

  # todo: review usage of scope --lf.20130108
  scope :like, lambda {|q|
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(name) LIKE :s", {:s => s}],
     :order => 'name'
    }
  }

  def institution
    self.authorship.first.institution
  end
end
