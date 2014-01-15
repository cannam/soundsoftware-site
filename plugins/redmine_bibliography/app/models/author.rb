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
    if self.authorships.first.nil?
      ""
    else
      self.authorships.first.institution
    end
  end

  def mail
    if self.authorships.first.nil?
      ""
    else
      self.authorships.first.mail
    end
  end

  # todo: need to fix the name getter
  def name
    if self.authorships.first.nil?
      ""
    else
      self.authorships.first.name
    end
  end

end
