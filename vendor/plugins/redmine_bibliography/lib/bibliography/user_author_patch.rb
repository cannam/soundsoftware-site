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
          :user_id => self.id                    
        }
        
        unless self.author.nil?
          logger.error { "We've got author" }          
          info[:name_on_paper] = self.author.name            

          if self.author.authorships.length > 0
            info[:email] = self.author.authorships.first.email
            info[:institution] = self.author.authorships.first.institution
          end

        else
          logger.error { "No author" }
          
          info[:name_on_paper] = "No Name"
          info[:email] = self.mail
          if not self.ssamr_user_detail.nil?
            info[:institution]  = self.ssamr_user_detail.institution_name
          end
        end
        
        return info
        
      end            
    end #InstanceMethods
    
  end #UserPublicationsPatch
end #RedmineBibliography