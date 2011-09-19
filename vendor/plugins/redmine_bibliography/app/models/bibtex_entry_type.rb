class BibtexEntryType < ActiveRecord::Base

  @@all_fields = [ "booktitle", "editor", "publisher", "chapter", "pages", "volume", "series", "address", "edition", "month", "year", "type", "note", "number", "journal", "howpublished", "key", "school" ]

  @@fields = Hash['article', ['journal', 'year', 'volume', 'number', 'pages', 'month', 'note' ], 
                  'book' , [ 'editor', 'publisher', 'volume', 'series', 'address', 'edition', 'month', 'year', 'note' ],
                  'booklet' , [ 'howpublished', 'address', 'year', 'month', 'note', 'key' ],
                  'conference', [ 'booktitle', 'year', 'editor', 'pages', 'organization', 'publisher', 'address', 'month', 'note' ],
                  'inbook', [ 'editor', 'publisher', 'chapter', 'pages', 'volume', 'series', 'address', 'edition', 'year', 'note' ],
                  'incollection', [ 'editor', 'publisher', 'chapter', 'pages', 'volume', 'series', 'address', 'edition', 'year', 'note' ],
                  'inproceedings', [ 'booktitle', 'year', 'editor', 'pages', 'organization', 'publisher', 'address', 'month', 'note' ],
                  'manual', [ 'organization', 'address', 'edition', 'month', 'year', 'note' ],
                  'masterthesis', [ 'school', 'year', 'address', 'month', 'note' ],
                  'misc', [ 'howpublished', 'month', 'year', 'note' ],
                  'phdthesis', [ 'school', 'year', 'address', 'month', 'note' ],
                  'proceedings', [ 'booktitle', 'year', 'editor', 'pages', 'organization', 'publisher', 'address', 'month', 'note' ],
                  'techreport', [ 'year', 'type', 'number', 'address', 'month', 'note' ],
                  'unpublished', [ 'note', 'month', 'year' ]]

  def redundant?
    name == 'conference'  # conference is a duplicate of inproceedings
  end

  def label
    l("field_bibtex_#{name}")
  end

  def self.fields (type)
    @@fields[ self.find(type).name ]    
  end

  def self.all_fields
    @@all_fields
  end
end
