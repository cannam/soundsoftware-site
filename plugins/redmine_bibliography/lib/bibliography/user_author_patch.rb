require_dependency 'user'

module Bibliography
  module UserAuthorPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      extend ClassMethods

    end #self.included

    module ClassMethods
    end

    module InstanceMethods

      def institution
        unless self.ssamr_user_detail.nil?
          institution_name = self.ssamr_user_detail.institution_name
        else
          institution_name = "No Institution Set"
        end
        return institution_name
      end

    end #InstanceMethods

  end #UserPublicationsPatch
end #RedmineBibliography
