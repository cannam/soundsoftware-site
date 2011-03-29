class CreatePublications < ActiveRecord::Migration
  def self.up
    create_table :publications do |t|
      t.column :title, :string
      t.column :bibtex_entry_id, :string
    end
  end

  def self.down
    drop_table :publications
  end
end
