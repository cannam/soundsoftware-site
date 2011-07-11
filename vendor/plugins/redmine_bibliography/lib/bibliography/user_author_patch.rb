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
      def get_author_name
        if self.author 
          self.author.name
        else
          "No Name"
        end
      end
      
      def get_author_info
        
      end            
    end #InstanceMethods
    
  end #UserPublicationsPatch
end #RedmineBibliography