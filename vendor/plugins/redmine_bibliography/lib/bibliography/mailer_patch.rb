require_dependency 'mailer'

module Bibliography
  module MailerPatch
      def self.included(base) # :nodoc:

        # Builds a tmail object used to email the specified user that a publication was created and the user is 
        # an author of that publication
        #
        # Example:
        #   publication_added(user) => tmail object
        #   Mailer.deliver_add_to_project(user) => sends an email to the registered user
        def publication_added(user, publication, project)

          @publication = publication
          @project = project

          set_language_if_valid user.language
          recipients user.mail
          subject l(:mail_subject_publication_added, Setting.app_title)
          body :publication_url => url_for( :controller => 'publications', :action => 'show', :id => publication.id ),
              :publication_title => publication.title

          render_multipart('publication_added', body)

        end
        
        
    end
  end
end
