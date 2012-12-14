class Authorship < ActiveRecord::Base
  unloadable

  belongs_to :author
  belongs_to :publication

  # attr_accessor :is_user, :author_user_id, :search_name, :identify_author, :search_results

  validates_associated :publication

  validates_presence_of :author, :message => "is not associated with an author. Authorship not saved."
  validates_presence_of :name_on_paper, :message => 'cannot be blank: publication not saved.'


  # todo: remove?
  #### before_save :associate_author_user

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

  def <=>(authorship)
    name_on_paper.downcase <=> authorship.name_on_paper.downcase
  end

  def mail
    return self.email
  end

  protected

  # need to remove this code from this part of the model
  #def associate_author_user
  #  case self.identify_author
  #    when "no"
  #      author = Author.new
  #      author.save
  #      self.author_id = author.id
  #    else
  #      selected = self.search_results
  #      selected_classname = Kernel.const_get(selected.split('_')[0])
  #      selected_id = selected.split('_')[1]
  #      object = selected_classname.find(selected_id)
#
  #      if object.respond_to? :name_on_paper
  #        # Authorship
  #        self.author_id = object.author.id
  #      else
  #        # User
  #        unless object.author.nil?
  #          self.author_id = object.author.id
  #        else
  #          author = Author.new
  #          object.author = author
  #          object.save
  #          self.author_id = object.author.id
  #        end
  #      end
  #  end
  #end
end
