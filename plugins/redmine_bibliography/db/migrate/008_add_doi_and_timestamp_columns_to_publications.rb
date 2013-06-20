class AddDoiAndTimestampColumnsToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications, :doi, :string
    add_timestamps :publications

  end

  def self.down
    remove_column :publications, :doi
    remove_timestamps :publications
  end
end
