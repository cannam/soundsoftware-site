require_dependency 'project'

module Bibliography
  module ProjectPublicationsPatch
    def self.included(base)
          base.class_eval do
            has_and_belongs_to_many :publications, :uniq => true

            scope :name_or_homepage_like, lambda {|q|
              s = "%#{q.to_s.strip.downcase}%"
              {:conditions => ["LOWER(name) LIKE :s OR LOWER(homepage) LIKE :s", {:s => s}],
               :order => 'name'
              }
            }
          end
    end #self.included

    module ProjectMethods




    end #ProjectMethods
  end #ProjectPublicationsPatch
end #RedmineBibliography