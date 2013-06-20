class CreateBibtexEntryTypes < ActiveRecord::Migration
  def self.up
    create_table :bibtex_entry_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :bibtex_entry_types
  end
end
