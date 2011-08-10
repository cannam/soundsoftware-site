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

      def get_author_info
        info = { 
          :name_on_paper =>  self.name,
          :email => self.mail,
          :institution => "",
          :author_user_id => self.id,
          :is_user => "1"                    
        }

        if not self.ssamr_user_detail.nil?
          info[:institution]  = self.ssamr_user_detail.institution_name
        end

        return info        
      end
                
    end #InstanceMethods
    
  end #UserPublicationsPatch
end #RedmineBibliography
