class CreateProjectsPublicationsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :projects_publications, :id => false do |t|
      t.integer :project_id
      t.integer :publication_id
    end
  end

  def self.down
    drop_table :projects_publications
  end
end