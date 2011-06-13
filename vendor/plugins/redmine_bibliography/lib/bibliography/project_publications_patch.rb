require_dependency 'project'

module Bibliography
  module ProjectPublicationsPatch
    def self.included(base)
          base.class_eval do
            has_and_belongs_to_many :publications
          end
        end
  end #ProjectPublicationsPatch
end #RedmineBibliography