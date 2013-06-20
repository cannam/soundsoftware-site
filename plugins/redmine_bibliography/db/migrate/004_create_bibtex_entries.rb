class CreateBibtexEntries < ActiveRecord::Migration
  def self.up
    create_table :bibtex_entries do |t|
      t.column :publication_id, :integer
      t.column :entry_type, :integer
      t.column :address, :string
      t.column :annote, :string
      t.column :booktitle, :string
      t.column :chapter, :string
      t.column :crossref, :string
      t.column :edition, :string
      t.column :editor, :string
      t.column :eprint, :string
      t.column :howpublished, :string
      t.column :journal, :string
      t.column :key, :string
      t.column :month, :string
      t.column :note, :text
      t.column :number, :string
      t.column :organization, :string
      t.column :pages, :string
      t.column :publisher, :string
      t.column :school, :string
      t.column :series, :string
      t.column :type, :string
      t.column :url, :string
      t.column :volume, :integer
      t.column :year, :integer
    end
  end

  def self.down
    drop_table :bibtex_entries
  end
end
