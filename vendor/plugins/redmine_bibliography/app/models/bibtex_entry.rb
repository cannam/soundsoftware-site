class BibtexEntry < ActiveRecord::Base
  unloadable

  belongs_to :publication
  validates_presence_of :entry_type, :publication

  attr_accessible :entry_type, :address, :annote, :booktitle, :chapter, :crossref, :edition, :editor, :eprint, :howpublished, :journal, :key, :month, :note, :number, :organization, :pages, :publisher, :school, :series, :type, :url, :volume, :year

  def entry_type_name
    entry_type = self.entry_type
    BibtexEntryType.find(entry_type).name
  end

  def entry_type_label
    entry_type = self.entry_type
    BibtexEntryType.find(entry_type).label
  end
end
