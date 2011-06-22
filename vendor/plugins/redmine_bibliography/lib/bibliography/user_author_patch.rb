require_dependency 'user'

module Bibliography
  module UserAuthorPatch
    def self.included(base)
          base.class_eval do
            has_one :publication
          end
    end #self.included
  end #UserPublicationsPatch
end #RedmineBibliography