require_dependency 'user'

module Bibliography
  module UserAuthorPatch    
    def self.included(base)
      base.send(:include, InstanceMethods) 
      extend ClassMethods     
          
      base.class_eval do
        has_one :publication
                                    
      end
    end #self.included
    
    module ClassMethods
    end  
    
    module InstanceMethods

      def get_author_info
        info = { 
          :name_on_paper => "",
          :email => "",
          :institution => "",
          :author_user_id => self.id,
          :is_user => "1"                    
        }
        
        if self.author.nil?
          logger.debug { "Bibliography: The current user has no author associated." }
          info[:name_on_paper] = self.name
          info[:email] = self.mail
          if not self.ssamr_user_detail.nil?
            info[:institution]  = self.ssamr_user_detail.institution_name
          end
        else
          logger.error { "Bibliography: We've got an author associated with the current user." }          
          info[:name_on_paper] = self.author.name            

          if self.author.authorships.length > 0
            info[:email] = self.author.authorships.first.email
            info[:institution] = self.author.authorships.first.institution
          end
        end        
        return info        
      end
                
    end #InstanceMethods
    
  end #UserPublicationsPatch
end #RedmineBibliography