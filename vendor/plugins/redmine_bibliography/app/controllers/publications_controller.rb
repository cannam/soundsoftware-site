# vendor/plugins/redmine_bibliography/app/controllers/publications_controller.rb

class PublicationsController < ApplicationController


  def new
    # we always try to create at least one publication
    @publication = Publication.new
    
    # the step we're at in the form
    @publication.current_step = session[:publication_step]
  end

  def create
    @publication = Publication.new(params[:publication])
    @publication.current_step = session[:publication_step]

    # contents of the paste text area
    bibtex_entry = params[:bibtex_entry]

    # debug message
    logger.error bibtex_entry

    # method for creating "pasted" bibtex entries
    if bibtex_entry
      parse_bibtex_text bibtex_entry
    end

    # form's flow control
    if params[:back_button]
      @publication.previous_step
    else
      @publication.next_step
    end

    session[:publication_step] = @publication.current_step

    render "new"
  end


  def index
    @publications = Publication.find(:all)
  end

  def edit
    logger.error "AAAA edit"

  end

  def update

    logger.error "AAAA update"


  end

  def show  
    @publication = Publication.find(params[id])
    @authors = @publication.authors
  end





  
  
  
  
  
  
  
  # parse string with bibtex authors
  def parse_authors(authors_entry)
    # in bibtex the authors are always seperated by "and"
    authors = authors_entry.split(" and ")
    
    # need to save all authors
    
    
    return authors
  end

  # parses the bibtex file
  def parse_bibtex_file

  end

  # parses a list of bibtex 
  def parse_bibtex_list(bibtex_list)
    bibliography = BibTeX.parse bibtex_list

    no_entries = bibliography.data.length

    puts "Gonna parse " + no_entries.to_s + " Bibtex entries"

    # parses the bibtex entries
    bibliography.data.map do |d|
      create_bibtex_entry d
    end

    @publication.bibtex_entry = @bentry

    if @publication.save
      puts "SAVED"
    else
      puts "NOT SAVED"
    end

    Rails.logger.error @publication.bibtex_entry
  end 



  def create_bibtex_entry(d)

    if d.class == BibTeX::Entry
      # creates a new BibTex instance
      @bentry = BibtexEntry.new

      d.fields.keys.map do |field|
        
        case field.to_s
        when "author"
          authors = parse_authors d[field]
          puts "Number of authors: " + authors.length.to_s
        when "title"
          puts "The title " + d[field]
          @publication.title = d[field]
        when "The institution"
          puts "institution " + d[field]
        when "email"
          puts "The email " + d[field]
        else
          @bentry[field] = d[field]
          puts field.to_s + " " + d[field]
        end
      end

      @bentry.save!
    end 
  end





end
