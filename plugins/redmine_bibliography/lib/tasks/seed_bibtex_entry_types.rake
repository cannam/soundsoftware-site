namespace :redmine do
  namespace :plugins do
    namespace :redmine_bibliography do

      task :seed_bibtex_entry_types  => :environment do    
        desc "Seeds the Bibtex Entry Types Table"
  
        quoted = ActiveRecord::Base.connection.quote_table_name('bibtex_entry_types')
        ActiveRecord::Base.connection.execute("TRUNCATE #{quoted}")

        open(File.dirname(__FILE__) + "/../../db/seed_data/bibtex_entry_types_list.txt") do |bibtex_entry_types|
          bibtex_entry_types.read.each_line do |bibtex_entry_type|
            BibtexEntryType.create(:name => bibtex_entry_type.chomp)
          end
        end
      end 

    end 
  end
end
