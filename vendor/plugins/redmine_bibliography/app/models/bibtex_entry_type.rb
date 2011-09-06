class BibtexEntryType < ActiveRecord::Base
  def redundant?
    name == 'conference'  # conference is a duplicate of inproceedings
  end
  def label
    l("field_bibtex_#{name}")
  end
end
