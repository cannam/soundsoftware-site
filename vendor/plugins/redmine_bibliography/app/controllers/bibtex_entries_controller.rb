class BibtexEntriesController < ApplicationController

  # parse string with bibtex authors
  # return an ordered array
  def parse_authors

  end

  # parses the bibtex file
  def parse_bibtex_file

  end

  def parse_bibtex_list(bibtex_list)
    bibliography = BibTeX.parse bibtex_list

    no_entries =  bibliography.data.length

    logger.error "Gonna parse " no_entries.to_s " Bibtex entries"

    # parses the bibtex entries
    bibliography.data.map do |d|
      create_bibtex_entry d
    end

    @publication.bibtex_entry = @bentry

    if @publication.save
      logger.error "SAVED"
    else
      logger.error "NOT SAVED"
    end

    logger.error @publication.bibtex_entry
  end 



  def create_bibtex_entry(d)
    result = ''
    if d.class == BibTeX::Entry
      @bentry = BibtexEntry.new

      d.fields.keys.map do |k|
        if k == "title"
          @publication.title = d[k]
        else
          @bentry[k] = d[k]
        end
      end
      @bentry.save!
    end 
  end

end