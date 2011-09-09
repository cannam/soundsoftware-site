class AddExternalUrlColumnToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications, :external_url, :string
  end

  def self.down
    remove_column :publications, :external_url
  end
end
